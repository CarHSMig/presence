# frozen_string_literal: true

require 'httparty'

module FaceAuth
  class CreateEmbeddings
    include HTTParty

    MAX_FILES = 5

    def initialize(student_id, files)
      @student_id = student_id
      @files = Array(files)
    end

    def create_embeddings
      validate_inputs

      body = build_request_body
      api_url = build_api_url('/embeddings')

      response = HTTParty.post(
        api_url,
        body: body,
        multipart: true
      )

      unless response.success?
        Rails.logger.error("Create embeddings API error: HTTP #{response.code} - #{response.body}")
        return nil
      end

      JSON.parse(response.body)
    rescue ArgumentError => e
      Rails.logger.error("Error creating embeddings: #{e.message}")
      nil
    rescue JSON::ParserError => e
      Rails.logger.error("Error parsing create embeddings response: #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.error("Unexpected error in create embeddings: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      nil
    end

    def perform
      create_embeddings
    end

    private

    def validate_inputs
      unless @student_id.present?
        raise ArgumentError, 'Student ID is required'
      end

      if @files.empty?
        raise ArgumentError, 'At least one file is required'
      end

      if @files.length > MAX_FILES
        raise ArgumentError, "Maximum #{MAX_FILES} files allowed, got #{@files.length}"
      end

      @files.each do |file|
        unless file.present?
          raise ArgumentError, 'All files must be present'
        end
      end
    end

    def build_request_body
      {
        student_id: @student_id.to_s,
        files: @files
      }
    end

    def build_api_url(path)
      base_url = ENV['FACE_AUTH_API_URL']
      raise ArgumentError, 'FACE_AUTH_API_URL environment variable is not set' unless base_url.present?

      base_url = base_url.strip
      base_url = "http://#{base_url}" unless base_url.start_with?('http://', 'https://')

      "#{base_url}#{path}"
    end
  end
end

