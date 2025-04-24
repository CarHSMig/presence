# frozen_string_literal: true

module Admin
  class CoursesController < ApplicationController
    before_action :authenticate_user_with_jwt

    def index
      courses = Course.all
      courses = courses.ransack(params[:q])
      @courses = courses.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @courses, class: { Course: SerializableCourse }, status: :ok
    end

    def show
      @course = Course.find_by(id: find_params)

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
      @course = Course.find_by(id: find_params)

      unless @course
        return render json: { error: 'Curso não encontrada' }, status: :not_found
      end

      if @course.update(course_params)
        render jsonapi: @course, class: { Course: SerializableCourse }, status: :ok
      else
        render json: @course.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @course = Course.find_by(id: find_params)

      unless @course
        return render json: { error: 'Curso não encontrado' }, status: :not_found
      end

      if @course.valid?
        @course.delete
        render json: { message: 'Curso excluído com sucesso' }, status: :ok
      else
        render json: @course.errors, status: :unprocessable_entity
      end
    end

    private

    def course_params
      params.require(:data).require(:attributes).permit(:name, :periods)
    end
  end
end
