# frozen_string_literal: true

module Admin
  class ParticipantsController < ApplicationController
    before_action :authenticate_user_with_jwt, only: %i[index show destroy export_participants]

    attr_reader :participant

    before_action :set_participant, only: %i[show destroy]

    before_action -> { authorize(Participant) }, only: %i[index export_participants]
    before_action -> { authorize(@participant) }, only: %i[show destroy]

    def index
      participants = Participant.includes(:student).where(event_id: event_id)
      participants = participants.ransack(params[:q])
      @participants = participants.result.page(params[:page]).per(params[:per_page] || 10)

      render jsonapi: @participants, include: include_options, class: {
        Participant: SerializableParticipant,
        Event: SerializableEvent,
        Student: SerializableStudent
      }, status: :ok
    end

    def show
      @participant = Participant.find_by(id: find_params, event_id: event_id)
      if @participant
        render jsonapi: @participants, include: include_options,
               class: { Participant: SerializableParticipant, Event: SerializableEvent, Student: SerializableStudent }, status: :ok
      else
        render json: { error: 'Participante não encontrado' }, status: :not_found
      end
    end

    def destroy
      @participant = Participant.find_by(id: find_params, event_id: event_id)
      return render json: { error: 'Participante não encontrado' }, status: :not_found unless @participant

      if @participant.valid?
        @participant.delete
        render jsonapi: @participant, include: include_options,
               class: { Participant: SerializableParticipant, Event: SerializableEvent, Student: SerializableStudent }, status: :ok
      else
        render json: @participant.errors, status: :not_found
      end
    end

    def export_participants
      event = Event.find_by(id: event_id)
      return render json: { error: 'Evento não encontrado' }, status: :not_found unless event

      participants = Participant.includes(:student).where(event: event)
      participants = participants.ransack(params[:q]).result if params[:q].present?

      case params[:format]
      when 'csv'
        send_data Participants::ExportCsv.new(participants).call,
                  filename: "#{event.name} #{format_datetime}.csv",
                  type: 'text/csv',
                  disposition: 'attachment'
      when 'xlsx'
        send_data Participants::ExportXlsx.new(participants).call,
                  filename: "#{event.name} #{format_datetime}.xlsx",
                  type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                  disposition: 'attachment'
      else
        render json: { error: 'Formato de exportação não suportado' }, status: :unprocessable_entity
      end
    end

    private

    def format_datetime
      Time.current.strftime('%d-%m-%Y_%H-%M')
    end

    def participant_params
      params.require(:data).require(:attributes).permit(
        :present, :location
      )
    end

    def set_participant
      @participant = Participant.find_by(id: find_params, event_id: event_id)
    end

    def event_id
      params['event_id']
    end
  end
end
