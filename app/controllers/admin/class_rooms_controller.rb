# frozen_string_literal: true

module Admin
  class ClassRoomsController < ApplicationController
    before_action :authenticate_user_with_jwt
    before_action :set_class_room, only: %i[show update destroy]

    before_action -> { authorize(ClassRoom) }, only: %i[index create]
    before_action -> { authorize(@class_room) }, only: %i[show update destroy]

    def index
      class_rooms = ClassRoom.where(course_id: params[:course_id]) if params[:course_id].present?
      class_rooms = class_rooms.ransack(params[:q])
      @class_rooms = class_rooms.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @class_rooms, include: include_options,
             class: { ClassRoom: SerializableClassRoom, Course: SerializableCourse }, status: :ok
    end

    def show
      render jsonapi: @class_room, include: include_options,
             class: { ClassRoom: SerializableClassRoom, Course: SerializableCourse }, status: :ok
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
      return render json: { error: 'Turma não encontrada' }, status: :not_found unless @class_room

      return if validate_class_room_period

      @class_room&.assign_attributes(class_room_params)

      if @class_room.valid?
        @class_room.save!
        render jsonapi: @class_room, class: { ClassRoom: SerializableClassRoom }, status: :ok
      else
        render json: @class_room.errors, status: :unprocessable_entity
      end
    end

    def destroy
      return render json: { error: 'Turma não encontrada' }, status: :not_found unless @class_room

      if @class_room.valid?
        @class_room.destroy
        render json: { message: 'Turma excluída com sucesso' }, status: :ok
      else
        render json: @class_room.errors, status: :unprocessable_entity
      end
    end

    private

    def set_class_room
      @class_room = ClassRoom.find_by(id: find_params)
    end

    def class_room_params
      params.require(:data).require(:attributes).permit(:name, :period)
    end

    def class_room_params_with_course
      class_room_params.merge(course_id: params[:course_id])
    end

    def validate_class_room_period
      course = @class_room&.course || Course.find_by(id: params[:course_id])

      if course && course.periods < @class_room.period
        render json: { error: 'O período da turma excede os períodos existentes do curso' },
               status: :unprocessable_entity
        return true
      end

      false
    end
  end
end
