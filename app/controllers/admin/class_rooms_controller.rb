# frozen_string_literal: true

module Admin
  class ClassRoomsController < ApplicationController
    before_action :authenticate_user_with_jwt

    def index
      class_rooms = ClassRoom.where(course_id: params[:course_id]) if params[:course_id].present?
      class_rooms = class_rooms.ransack(params[:q])
      @class_rooms = class_rooms.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @class_rooms, include: include_options, class: { ClassRoom: SerializableClassRoom, Course: SerializableCourse }, status: :ok
    end

    def show
      @class_room = ClassRoom.find_by(id: find_params)

      if @class_room
        render jsonapi: @class_room, include: include_options, class: { ClassRoom: SerializableClassRoom, Course: SerializableCourse }, status: :ok
      else
        render json: { error: 'Turma não encontrada' }, status: :not_found
      end
    end

    def create
      @class_room = ClassRoom.new(class_room_params_with_course)

      return if validate_class_room_period

      if @class_room.save
        render jsonapi: @class_room, class: { ClassRoom: SerializableClassRoom }, status: :created
      else
        render json: @class_room.errors, status: :unprocessable_entity
      end
    end

    def update
      @class_room = ClassRoom.find_by(id: find_params)

      unless @class_room
        return render json: { error: 'Turma não encontrada' }, status: :not_found
      end

      return if validate_class_room_period

      if @class_room.update(class_room_params_with_course)
        render jsonapi: @class_room, class: { ClassRoom: SerializableClassRoom }, status: :ok
      else
        render json: @class_room.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @class_room = ClassRoom.find_by(id: find_params)

      unless @class_room
        return render json: { error: 'Turma não encontrada' }, status: :not_found
      end

      if @class_room.valid?
        @class_room.destroy
        render json: { message: 'Turma excluída com sucesso' }, status: :ok
      else 
        render json: @class_room.errors, status: :unprocessable_entity
      end
    end

    private

    def class_room_params
      params.require(:data).require(:attributes).permit(:name, :period)
    end

    def class_room_params_with_course
      class_room_params.merge(course_id: params[:course_id])
    end

    def validate_class_room_period
      course = @class_room.course

      if course.periods < @class_room.period
        render json: { error: "O período da turma excede os períodos existentes do curso" }, status: :unprocessable_entity
        return true
      end

      false
    end
  end
end
