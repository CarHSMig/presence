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
      ActiveRecord::Base.transaction do
        user = nil
        if params[:email].present?
          user = User.create!(
            name: params[:name],
            email: params[:email],
            password: SecureRandom.hex(10),
            admin: false
          )

          user.send_reset_password_instructions
        end
        student = Student.create!(
          name: params[:name],
          ra: params[:ra],
          class_room_id: params[:class_room_id],
          user: user
        )

        render jsonapi: student, include: [:class_room], class: { Student: SerializableStudent, ClassRoom: SerializableClassRoom }, status: :created
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
