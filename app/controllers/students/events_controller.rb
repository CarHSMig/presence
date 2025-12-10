# frozen_string_literal: true

module Students
  class EventsController < ApplicationController
    include ActiveModel::Model
    before_action :authenticate_user_with_jwt
    before_action :set_event, only: %i[show]

    before_action -> { authorize(Event) }, only: %i[index]

    attr_reader :event, :class_room_ids

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
             class: { Event: SerializableEvent, Course: SerializableCourse }, status: :ok
    end

    private

    def set_event
      @event = Event.find_by(id: find_params)
    end

    def generate_presence_url
      base_url = ENV['FRONTEND_URL']
      "#{base_url}/participantes/#{@event.id}"
    end
  end
end
