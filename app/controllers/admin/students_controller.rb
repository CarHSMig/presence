# frozen_string_literal: true

module Admin
  class StudentsController < ApplicationController
    before_action :authenticate_user_with_jwt

    before_action :set_student, only: %i[show update destroy delete_embedding add_embedding]

    before_action -> { authorize(Student) }, only: %i[index create]
    before_action -> { authorize(Student, :import?) }, only: %i[import]
    before_action -> { authorize(Student, :template?) }, only: %i[template]
    before_action -> { authorize(@student) }, only: %i[show update destroy delete_embedding add_embedding]

    def index
      students = Student.all
      students = students.where(class_room_id: params[:class_room_id]) if params[:class_room_id].present?
      students = students.ransack(params[:q])
      @students = students.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @students, include: include_options,
             class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom }, status: :ok
    end

    def show
      if @student
        render jsonapi: @student, include: include_options,
               class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom }, status: :ok
      else
        render json: { error: 'Estudante não encontrado' }, status: :not_found
      end
    end

    def create
      students = []
      errors = []
      embedding_errors = []

      create_params.each_with_index do |student_param, index|
        full_params = student_param.merge(class_room_id: params[:class_room_id])
        student = StudentManagement::Create.new(full_params).call
        students << student

        files = get_student_files(index)
        if files.present?
          embedding_result = create_embeddings_for_student(student, files)
          embedding_errors << { student_id: student.id, error: embedding_result[:error] } unless embedding_result[:success]
        end
      rescue ActiveRecord::RecordInvalid => e
        errors << {
          attributes: student_param,
          error: e.message
        }
      end

      render_response_for_create(students, errors, embedding_errors)
    end

    def update
      return render json: { error: 'Estudante não encontrada' }, status: :not_found unless @student

      @student&.assign_attributes(update_params)

      if @student.valid?
        @student.save!

        files = get_student_files
        if files.present?
          embedding_result = create_embeddings_for_student(@student, files)
          unless embedding_result[:success]
            Rails.logger.warn("Erro ao criar embeddings para estudante #{@student.id}: #{embedding_result[:error]}")
          end
        end

        render jsonapi: @student, include: include_options,
               class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom }, status: :ok
      else
        render json: @student.errors, status: :unprocessable_entity
      end
    end

    def destroy
      return render json: { error: 'Estudante não encontrada' }, status: :not_found unless @student

      if @student.valid?
        @student.delete
        render jsonapi: @student, include: include_options,
               class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom }, status: :ok
      else
        render json: @student.errors, status: :not_found
      end
    end

    def delete_embedding
      return render json: { error: 'Estudante não encontrado' }, status: :not_found unless @student

      embedding_id = params[:embedding_id]
      return render json: { error: 'ID do embedding é obrigatório' }, status: :bad_request unless embedding_id.present?

      facial_profile = FacialProfile.find_by(id: embedding_id, student_id: @student.id)
      
      unless facial_profile
        return render json: { error: 'Embedding não encontrado para este estudante' }, status: :not_found
      end

      api_deleted = FaceAuth::DeleteEmbedding.new(embedding_id).perform

      if facial_profile.destroy
        render json: { 
          message: 'Embedding deletado com sucesso',
          api_deleted: api_deleted
        }, status: :ok
      else
        render json: { 
          error: 'Erro ao deletar embedding',
          errors: facial_profile.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Erro ao deletar embedding: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      render json: { error: 'Erro ao processar exclusão do embedding' }, status: :internal_server_error
    end

    def add_embedding
      return render json: { error: 'Estudante não encontrado' }, status: :not_found unless @student

      files = get_embedding_files
      return render json: { error: 'Arquivo de imagem é obrigatório' }, status: :bad_request unless files.present?

      if files.length > FaceAuth::CreateEmbeddings::MAX_FILES
        return render json: { 
          error: "Máximo de #{FaceAuth::CreateEmbeddings::MAX_FILES} arquivos permitidos, recebidos #{files.length}" 
        }, status: :bad_request
      end

      embedding_result = create_embeddings_for_student(@student, files)

      if embedding_result[:success]
        render json: { 
          message: 'Embedding criado com sucesso',
          result: embedding_result[:result]
        }, status: :created
      else
        render json: { 
          error: embedding_result[:error] || 'Erro ao criar embedding'
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Erro ao adicionar embedding: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      render json: { error: 'Erro ao processar criação do embedding' }, status: :internal_server_error
    end

    def import
      render json: { error: 'Arquivo não enviado' }, status: :bad_request and return if params[:file].blank?

      begin
        result = StudentManagement::ImportDispatcher.new(params[:file].path, params[:class_room_id]).call

        if result[:errors].empty?
          render jsonapi: result[:students], include: [:class_room],
                 class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom },
                 status: :created
        else
          render json: {
            created: result[:students].map { |s| { id: s.id, type: 'student' } },
            errors: result[:errors]
          }, status: :multi_status
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end

    def template
      template_service = Students::ImportStudent::ImportTemplate.new(params)
      file_content = template_service.template
      format = params[:format].to_s.downcase

      filename = "template_importacao_alunos.#{format == 'xlsx' ? 'xlsx' : 'csv'}"
      content_type = if format == 'xlsx'
                       'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                     else
                       'text/csv'
                     end

      send_data file_content, filename: filename, type: content_type
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_student
      @student = Student.find_by(id: find_params, class_room_id: params[:class_room_id])
    end

    def create_params
      data = params.require(:data)

      data = parse_json_if_string(data)
      
      data = Array(data) unless data.is_a?(Array)
      
      data.map do |item|
        item = parse_json_if_string(item)
        
        item = ActionController::Parameters.new(item) if item.is_a?(Hash)
        
        item.require(:attributes).permit(:name, :ra, :email)
      end
    end

    def update_params
      data = params.require(:data)
      
      data = parse_json_if_string(data)
      
      data = ActionController::Parameters.new(data) if data.is_a?(Hash)
      
      data.require(:attributes).permit(:name, :ra)
    end

    def get_embedding_files
      files = params[:file] || params[:files] || params.dig(:data, :attributes, :file) || params.dig(:data, :attributes, :files)

      if files.present?
        files = Array(files) unless files.is_a?(Array)
        files = files.select { |f| f.present? && f.is_a?(ActionDispatch::Http::UploadedFile) }
      else
        files = []
      end

      files.present? ? files : nil
    end

    def get_student_files(index = nil)
      all_files = extract_all_files
      return nil if all_files.blank?

      if index.present?
        files = all_files
      else
        files = all_files
      end

      files.present? ? files : nil
    end

    def extract_all_files
      files = params[:files]
      
      if files.is_a?(Array)
        return files.select { |f| f.present? && f.is_a?(ActionDispatch::Http::UploadedFile) }
      end
      
      if files.is_a?(ActionDispatch::Http::UploadedFile)
        return [files]
      end
      
      if files.blank?
        indexed_files = []
        (0..4).each do |i|
          indexed_file = params[:"files[#{i}]"]
          break if indexed_file.blank?
          indexed_files << indexed_file if indexed_file.is_a?(ActionDispatch::Http::UploadedFile)
        end
        return indexed_files if indexed_files.present?
      end
      
      files ||= params.dig(:data, :attributes, :files)
      
      if files.present?
        files = Array(files) unless files.is_a?(Array)
        files = files.select { |f| f.present? && f.is_a?(ActionDispatch::Http::UploadedFile) }
      else
        files = []
      end
      
      files
    end

    def calculate_files_per_student(total_files, student_index)
      students_count = create_params.length
      files_per_student = (total_files.to_f / students_count).ceil
      
      start_index = student_index * files_per_student
      end_index = [start_index + files_per_student - 1, total_files - 1].min
      
      { start: start_index, end: end_index }
    end

    def create_embeddings_for_student(student, files)
      return { success: false, error: 'Arquivos não fornecidos' } unless files.present?

      service = FaceAuth::CreateEmbeddings.new(student.id, files)
      result = service.perform

      if result.present?
        { success: true, result: result }
      else
        { success: false, error: 'Erro ao criar embeddings. Verifique os logs para mais detalhes.' }
      end
    rescue StandardError => e
      Rails.logger.error("Erro ao criar embeddings para estudante #{student.id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      { success: false, error: e.message }
    end

    def render_response_for_create(students, errors, embedding_errors)
      if errors.empty? && embedding_errors.empty?
        render jsonapi: students, include: [:class_room],
               class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom },
               status: :created
      else
        response_data = {
          created: students.map { |s| { id: s.id, type: 'student' } },
          errors: errors,
          embedding_errors: embedding_errors
        }
        render json: response_data, status: :multi_status
      end
    end

    def parse_json_if_string(value)
      return value unless value.is_a?(String)
      
      begin
        parsed = JSON.parse(value)
        if parsed.is_a?(Array) && parsed.first.is_a?(String)
          parsed.map { |item| parse_json_if_string(item) }
        else
          parsed
        end
      rescue JSON::ParserError
        value
      end
    end
  end
end
