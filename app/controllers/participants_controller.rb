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

    return render jsonapi: participant, include: include_options, class: { Participant: SerializableParticipant, Event: SerializableEvent }, status: :ok if participant.present?

    validation_results = validate_presence_requirements(student, participant, event)
    
    unless validation_results[:success]
      render json: { error: validation_results[:error] }, status: :unprocessable_entity
      return
    end

    update_participant_presence(participant, validation_results)
    participant.save

    render jsonapi: participant, include: include_options, class: { Participant: SerializableParticipant, Event: SerializableEvent }, status: :ok
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

  def validate_presence_requirements(student, participant, event)
    validation_results = {
      success: true,
      error: nil,
      location: nil,
      location_validated: false,
      face_auth_validated: false
    }

    if event.location_optional
      location_result = validate_location(event)
      unless location_result[:success]
        validation_results[:success] = false
        validation_results[:error] = location_result[:error]
        return validation_results
      end
      validation_results[:location] = location_result[:location]
      validation_results[:location_validated] = true
    end

    if event.face_auth
      photo_file = get_photo_file
      unless photo_file
        validation_results[:success] = false
        validation_results[:error] = 'Foto é obrigatória para autenticação facial'
        return validation_results
      end

      face_auth_result = validate_face_auth(student, photo_file)
      unless face_auth_result[:success]
        validation_results[:success] = false
        validation_results[:error] = face_auth_result[:error]
        return validation_results
      end
      validation_results[:face_auth_validated] = true
    end

    unless event.location_optional || event.face_auth
      validation_results[:success] = true
      return validation_results
    end

    validation_results
  end

  def validate_location(event)
    latitude = confirm_presence_params[:latitude]
    longitude = confirm_presence_params[:longitude]

    unless latitude.present? && longitude.present?
      return { success: false, error: 'Latitude e longitude são obrigatórias para validação de localização' }
    end

    event_latitude = format('%.10f', event.latitude).to_f
    event_longitude = format('%.10f', event.longitude).to_f

    location_service = Location::GetLocationParticipant.new(
      latitude.to_f,
      longitude.to_f,
      event_latitude,
      event_longitude
    )

    distance = location_service.distance(latitude.to_f, longitude.to_f, event.latitude, event.longitude)

    if distance > Location::GetLocationParticipant::ALLOWED_RADIUS
      return { success: false, error: 'Participante está fora da área do evento' }
    end

    location_data = location_service.perform
    location_address = location_data&.dig("address") || location_data&.dig("display_name")

    { success: true, location: location_address, error: nil }
  rescue StandardError => e
    Rails.logger.error("Erro ao validar localização: #{e.message}")
    { success: false, error: 'Erro ao validar localização do participante' }
  end

  def validate_face_auth(student, photo_file)
    face_auth_service = FaceAuth::ValidateFaceAuth.new(student, photo_file)
    response = face_auth_service.perform

    unless response.present? && response.is_a?(Hash)
      return { success: false, error: 'Erro ao processar autenticação facial' }
    end

    match_result = response["match"] || response[:match]

    unless match_result.is_a?(TrueClass) || match_result.is_a?(FalseClass)
      Rails.logger.error("Resposta inválida da API de face auth: #{response.inspect}")
      return { success: false, error: 'Resposta inválida da API de autenticação facial' }
    end

    if match_result == true
      { success: true, error: nil }
    else
      { success: false, error: 'Aluno não reconhecido pela autenticação facial' }
    end
  rescue StandardError => e
    Rails.logger.error("Erro ao validar autenticação facial: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
    { success: false, error: 'Erro ao processar autenticação facial' }
  end

  def update_participant_presence(participant, validation_results)
    participant.present = true
    participant.location = validation_results[:location] if validation_results[:location].present?
  end

  def get_photo_file
    params[:photo] || params[:file] || params.dig(:data, :attributes, :photo)
  end
end
