# frozen_string_literal: true

module Admin
  class EventsController < ApplicationController
    include ActiveModel::Model
    before_action :authenticate_user_with_jwt
    before_action :set_event, only: %i[show update destroy]

    before_action -> { authorize(Event) }, only: %i[index create classrooms_by_courses]
    before_action -> { authorize(@event) }, only: %i[show update destroy]

    attr_reader :event, :class_room_ids, :course_ids

    def index
      events = policy_scope(Event)

      if params[:finished]
        events = events.finished if ActiveModel::Type::Boolean.new.cast(params[:finished])
      elsif params[:upcoming]
        events = events.upcoming if ActiveModel::Type::Boolean.new.cast(params[:upcoming])
      elsif params[:in_progress]
        events = events.in_progress if ActiveModel::Type::Boolean.new.cast(params[:in_progress])
      end

      events = events.ransack(params[:q])
      @events = events.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @events, include: include_options,
             class: { Event: SerializableEvent, Course: SerializableCourse, ClassRoom: SerializableClassRoom }, status: :ok
    end

    def classrooms_by_courses
      course_ids = params[:course_ids]

      unless course_ids.present?
        return render json: { error: 'IDs dos cursos não fornecidos' },
                      status: :unprocessable_entity
      end

      @classrooms = ClassRoom.where(course_id: course_ids).includes(:course)

      render jsonapi: @classrooms,
             class: { ClassRoom: SerializableClassRoom, Course: SerializableCourse },
             include: [:course],
             status: :ok
    end

    def show
      if @event
        render jsonapi: @event, include: include_options,
               class: { Event: SerializableEvent, Course: SerializableCourse, ClassRoom: SerializableClassRoom }, status: :ok, meta: { presence_url: generate_presence_url }
      else
        render json: { error: 'Evento não encontrado' }, status: :not_found
      end
    end

    def create
      @event = Event.new(event_params)
      get_location(event_params['location'])
      @class_room_ids = event_params['class_room_ids']
      @course_ids = event_params['course_ids']

      return if common_validates

      if @event.valid?
        @event.save!
        handle_event_save_tasks
      else
        render json: @event.errors, status: :unprocessable_entity
      end
    end

    def update
      return render json: { error: 'Evento não encontrado' }, status: :not_found unless @event

      @event&.assign_attributes(event_params)

      location = event_params['location']
      @class_room_ids = event_params['class_room_ids']
      @course_ids = event_params['course_ids']
      get_location(location) if location.present?

      return if common_validates

      if @event.valid?
        @event.save!
        handle_event_save_tasks
      else
        render json: @event.errors, status: :unprocessable_entity
      end
    end

    def destroy
      return render json: { error: 'Evento não encontrado' }, status: :not_found unless @event

      if @event.valid?
        @event.delete
        render jsonapi: @event, include: include_options,
               class: { Event: SerializableEvent, Course: SerializableCourse, ClassRoom: SerializableClassRoom }, status: :ok
      else
        render json: @event.errors, status: :not_found
      end
    end

    private

    def set_event
      @event = Event.find_by(id: find_params)
    end

    def event_params
      params.require(:data).require(:attributes).permit(
        :name, :description, :event_start, :event_end, :location, course_ids: [], class_room_ids: []
      )
    end

    def handle_event_save_tasks
      create_class_rooms_events
      create_courses_events
      generate_participants
      render jsonapi: @event, include: include_options,
             class: { Event: SerializableEvent, Course: SerializableCourse, ClassRoom: SerializableClassRoom }, status: :ok, meta: { presence_url: generate_presence_url }
    end

    def common_validates
      return true if validate_start_date
      return true if validate_end_date
      return true if validate_classroom_course

      false
    end

    def validate_start_date
      return unless event.event_start.present?

      event_start = event.event_start.in_time_zone

      return unless event_start < Time.current

      render json: { error: 'Você não pode definir datas anteriores à atual' }, status: :unprocessable_entity
    end

    def validate_end_date
      return unless event.event_end.present?

      event_end = event.event_end.in_time_zone
      event_start = event.event_start.in_time_zone

      return unless event_end < event_start

      render json: { error: 'A data de encerramento não pode ser anterior a data de início' },
             status: :unprocessable_entity
    end

    def validate_classroom_course
      return unless class_room_ids.present?

      class_room_ids.each do |class_room_id|
        class_room = ClassRoom.find_by(id: class_room_id)
        next if (course_ids & [class_room.course_id]).any?

        render json: { error: "A turma #{class_room.name} não pertence a nenhum dos cursos associados ao evento" },
               status: :unprocessable_entity
        return true
      end

      false
    end

    def create_courses_events
      return unless course_ids.present?

      course_ids.each do |course_id|
        unless CoursesEvent.exists?(event_id: event.id, course_id: course_id)
          CoursesEvent.create(event_id: event.id, course_id: course_id)
        end
      end
    end

    def create_class_rooms_events
      return unless class_room_ids.present?

      class_room_ids.each do |class_room_id|
        unless ClassRoomsEvent.exists?(event_id: event.id, class_room_id: class_room_id)
          ClassRoomsEvent.create(event_id: event.id, class_room_id: class_room_id)
        end
      end
    end

    def generate_participants
      return unless class_room_ids.present?

      class_room_ids.each do |class_room_id|
        students = Student.where(class_room_id: class_room_id)

        students.each do |student|
          unless Participant.exists?(event_id: event.id, student_id: student.id)
            Participant.create(
              event_id: event.id,
              student_id: student.id,
              present: false,
              location: nil
            )
          end
        end
      end
    end

    def get_location(location)
      location = Location::GetLocation.new(location).perform
      event.location = location.dig(0, 'address')
      event.latitude = location.dig(0, 'lat')
      event.longitude = location.dig(0, 'lon')
    end

    def generate_presence_url
      base_url = ENV['FRONTEND_URL']
      "#{base_url}/participants/#{@event.id}"
    end
  end
end
