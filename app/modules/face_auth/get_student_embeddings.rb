# frozen_string_literal: true

require 'httparty'

module FaceAuth
  class GetStudentEmbeddings
    include HTTParty

    def initialize(student_id)
      @student_id = student_id
    end

    def get_embeddings
      unless @student_id.present?
        raise ArgumentError, 'Student ID is required'
      end

      api_url = build_api_url("/embeddings/student/#{@student_id}")

      response = HTTParty.get(api_url)

      unless response.success?
        Rails.logger.error("Get embeddings API error: HTTP #{response.code} - #{response.body}")
        return nil
      end

      JSON.parse(response.body)
    rescue ArgumentError => e
      Rails.logger.error("Error getting embeddings: #{e.message}")
      nil
    rescue JSON::ParserError => e
      Rails.logger.error("Error parsing get embeddings response: #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.error("Unexpected error in get embeddings: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      nil
    end

    def perform
      get_embeddings
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

