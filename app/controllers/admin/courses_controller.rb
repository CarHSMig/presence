# frozen_string_literal: true

module Admin
  class CoursesController < ApplicationController
    before_action :authenticate_user_with_jwt
    before_action :set_course, only: %i[show update destroy]

    before_action -> { authorize(Course) }, only: %i[index create]
    before_action -> { authorize(@course) }, only: %i[show update destroy]

    def index
      courses = Course.all
      courses = courses.ransack(params[:q])
      @courses = courses.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @courses, class: { Course: SerializableCourse }, status: :ok
    end

    def show
      if @course
        render jsonapi: @course, class: { Course: SerializableCourse }, status: :ok
      else
        render json: { error: 'Curso não encontrado' }, status: :not_found
      end
    end

    def create
      @course = Course.new(course_params)

      if @course.save
        render jsonapi: @course, class: { Course: SerializableCourse }, status: :created
      else
        render json: @course.errors, status: :unprocessable_entity
      end
    end

    def update
      return render json: { error: 'Curso não encontrada' }, status: :not_found unless @course

      @course&.assign_attributes(course_params)

      if @course.valid?
        @course.save!
        render jsonapi: @course, class: { Course: SerializableCourse }, status: :ok
      else
        render json: @course.errors, status: :unprocessable_entity
      end
    end

    def destroy
      return render json: { error: 'Curso não encontrado' }, status: :not_found unless @course

      if @course.valid?
        @course.delete
        render json: { message: 'Curso excluído com sucesso' }, status: :ok
      else
        render json: @course.errors, status: :unprocessable_entity
      end
    end

    private

    def set_course
      @course = Course.find_by(id: find_params)
    end

    def course_params
      params.require(:data).require(:attributes).permit(:name, :periods)
    end
  end
end
