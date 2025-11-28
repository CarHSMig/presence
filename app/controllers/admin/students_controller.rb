# frozen_string_literal: true

module Admin
  class StudentsController < ApplicationController
    before_action :authenticate_user_with_jwt

    before_action :set_student, only: %i[show update destroy]

    before_action -> { authorize(Student) }, only: %i[index create]
    before_action -> { authorize(Student, :import?) }, only: %i[import]
    before_action -> { authorize(Student, :template?) }, only: %i[template]
    before_action -> { authorize(@student) }, only: %i[show update destroy]

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
      params.require(:data).map do |item|
        item.require(:attributes).permit(:name, :ra, :email)
      end
    end

    def update_params
      params.require(:data).require(:attributes).permit(:name, :ra)
    end

    def get_student_files(index = nil)
      if index.present?
        files = params.dig(:files, index) || params.dig(:data, index, :files) || params.dig(:data, index, :attributes, :files)
      else
        files = params[:files] || params.dig(:data, :attributes, :files)
      end

      files = Array(files) if files.present?
      files&.reject(&:blank?)
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
  end
end
