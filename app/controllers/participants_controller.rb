# frozen_string_literal: true

class ParticipantsController < ApplicationController
  attr_reader :participant

  def confirm_presence
    student = find_student
    return unless student

    event = Event.find_by(id: params["event_id"])
    return render json: { error: 'Evento não encontrado' }, status: :not_found unless event

    participant = find_participant(student, event)
    return unless participant

    return if common_validates(event)

    if event.location_optional
      if participant.present == false
        presence_validated, location, error = validate_location(participant, event)

        if presence_validated == true
          participant.update(present: true, location: location)
          render jsonapi: participant, include: include_options, class: { Participant: SerializableParticipant, Event: SerializableEvent }, status: :ok
        else
          render json: { error: error }, status: :unprocessable_entity
        end
      else
        render jsonapi: participant, include: include_options, class: { Participant: SerializableParticipant, Event: SerializableEvent }, status: :ok
      end
    else
      participant.update(present: true, location: nil)
      render jsonapi: participant, include: include_options, class: { Participant: SerializableParticipant, Event: SerializableEvent }, status: :ok
    end
  end

  def show_event
    event = Event.find_by(id: params["event_id"])

    if event
      render jsonapi: event, include: include_options, class: { Event: SerializableEvent, Course: SerializableCourse }, status: :ok
    else
      render json: { error: 'Evento não encontrado' }, status: :not_found
    end
  end

  private

  def confirm_presence_params
    params.require(:data).require(:attributes).permit(
      :ra, :longitude, :latitude
    )
  end

  def find_student
    student = Student.find_by( ra: confirm_presence_params["ra"] )

    unless student
      render json: { error: 'Esse RA não pertence a nenhum aluno' }, status: :not_found
      return nil
    end

    student
  end

  def find_participant(student, event)
    participant = Participant.find_by(student_id: student.id, event: event)

    unless participant
      render json: { error: 'Participante não encontrado' }, status: :not_found
      return nil
    end

    participant
  end

  def common_validates(event)
    return true if validate_event_start_date(event)
    return true if validate_event_end_date(event)
    false
  end

  def validate_event_start_date(event)
    if event.event_start > Time.current
      render json: { error: 'Evento ainda não começou' }, status: :unprocessable_entity
      return true
    end
    false
  end

  def validate_event_end_date(event)
    if event.event_end < Time.current
      render json: { error: 'Evento já terminou' }, status: :unprocessable_entity
      return true
    end
    false
  end

  def validate_location(participant, event)
    if participant.present == false
      event_latitude = format('%.10f', event.latitude).to_f
      event_longitude = format('%.10f', event.longitude).to_f

      location_service = Location::GetLocationParticipant.new(
        confirm_presence_params[:latitude],
        confirm_presence_params[:longitude],
        event_latitude,
        event_longitude
      )

      distance = location_service.distance(confirm_presence_params[:latitude], confirm_presence_params[:longitude], event.latitude, event.longitude)
      
      if distance > Location::GetLocationParticipant::ALLOWED_RADIUS
        return {present: false, location: nil, error: 'Participante está fora da área do evento' }
      end

      location = location_service.perform

      {present: true, location: location["address"], error: nil }
    else
      {present: true, location: nil, error: nil }
    end
  end
end
