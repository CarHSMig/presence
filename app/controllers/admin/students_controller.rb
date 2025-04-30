# frozen_string_literal: true

module Admin
  class StudentsController < ApplicationController
    before_action :authenticate_user_with_jwt

    before_action :set_student, only: %i[show]

    before_action -> { authorize(Student) }, only: %i[index create]
    before_action -> { authorize(Student, :import?) }, only: %i[import]
    before_action -> { authorize(Student, :template?) }, only: %i[template]
    before_action -> { authorize(@student) }, only: %i[show]

    def index
      students = Student.all
      students = students.where(class_room_id: params[:class_room_id]) if params[:class_room_id].present?
      students = students.ransack(params[:q])
      @students = students.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @students, include: include_options,
             class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom }, status: :ok
    end

    def show
      @student = Student.find_by(id: find_params, class_room_id: params[:class_room_id])

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

      create_params.each do |student_param|
        full_params = student_param.merge(class_room_id: params[:class_room_id])
        student = StudentManagement::Create.new(full_params).call
        students << student
      rescue ActiveRecord::RecordInvalid => e
        errors << {
          attributes: student_param,
          error: e.message
        }
      end

      if errors.empty?
        render jsonapi: students, include: [:class_room],
               class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom },
               status: :created
      else
        render json: {
          created: students.map { |s| { id: s.id, type: 'student' } },
          errors: errors
        }, status: :multi_status
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
      template_service = ImportStudent::ImportTemplate.new(params)
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
      @student = Student.find_by(id: find_params)
    end

    def create_params
      params.require(:data).map do |item|
        item.require(:attributes).permit(:name, :ra, :email)
      end
    end
  end
end
