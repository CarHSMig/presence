require 'httparty'

module FaceAuth
  class ValidateFaceAuth
    include HTTParty

    def initialize(student, photo_file)
      @student = student
      @photo_file = photo_file
    end

    def validate_face_auth
      unless @student.present? && @photo_file.present?
        raise ArgumentError, 'Student and photo file are required'
      end

      api_url = build_api_url('/verify')

      response = HTTParty.post(
        api_url,
        body: {
          student_id: @student.id,
          file: @photo_file
        }
      )

      unless response.success?
        Rails.logger.error("Face auth API error: HTTP #{response.code} - #{response.body}")
        return nil
      end

      JSON.parse(response.body)
    rescue ArgumentError => e
      Rails.logger.error("Error validating face auth: #{e.message}")
      nil
    rescue JSON::ParserError => e
      Rails.logger.error("Error parsing face auth response: #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.error("Unexpected error in face auth: #{e.message}")
      nil
    end

    def perform
      validate_face_auth
    end

    private

    def build_api_url(path)
      base_url = ENV['FACE_AUTH_API_URL']
      raise ArgumentError, 'FACE_AUTH_API_URL environment variable is not set' unless base_url.present?

      base_url = base_url.strip
      base_url = "http://#{base_url}" unless base_url.start_with?('http://', 'https://')

      "#{base_url}#{path}"
    end
  end
end