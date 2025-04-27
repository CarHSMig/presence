# frozen_string_literal: true

module Admin
  class StudentsController < ApplicationController
    before_action :authenticate_user_with_jwt

    def index
      students = Student.all
      students = students.where(class_room_id: params[:class_room_id]) if params[:class_room_id].present?
      students = students.ransack(params[:q])
      @students = students.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @students, include: include_options, class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom }, status: :ok
    end

    def show
      @student = Student.find_by(id: find_params)

      if @student
        render jsonapi: @student, include: include_options, class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom }, status: :ok
      else
        render json: { error: 'Estudante não encontrado' }, status: :not_found
      end
    end

    def create
      students = []
      errors = []

      create_params.each do |student_param|
        begin
          full_params = student_param.merge(class_room_id: params[:class_room_id])
          student = StudentManagement::Create.new(full_params).call
          students << student
        rescue ActiveRecord::RecordInvalid => e
          errors << {
            attributes: student_param,
            error: e.message
          }
        end
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

    private

    def create_params
      params.require(:data).map do |item|
        item.require(:attributes).permit(:name, :ra, :email)
      end
    end
  end
end
