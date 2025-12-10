# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'

module FaceAuth
  class CreateEmbeddings
    MAX_FILES = 5

    def initialize(student_id, files)
      @student_id = student_id
      @files = Array(files)
    end

    def create_embeddings
      validate_inputs

      api_url = build_api_url('/embeddings')
      payload = build_request_payload

      response = send_request(api_url, payload)

      unless response.success?
        Rails.logger.error("Create embeddings API error: HTTP #{response.status} - #{response.body}")
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
      raise ArgumentError, 'Student ID is required' unless @student_id.present?
      raise ArgumentError, 'At least one file is required' if @files.empty?
      raise ArgumentError, "Maximum #{MAX_FILES} files allowed, got #{@files.length}" if @files.length > MAX_FILES

      @files.each do |file|
        unless file.is_a?(ActionDispatch::Http::UploadedFile)
          raise ArgumentError, 'All files must be valid UploadedFile instances'
        end
      end
    end

    def build_request_payload
      payload = {
        student_id: @student_id.to_s
      }

      @files.each do |file|
        payload[:files] ||= []
        payload[:files] << file.tempfile
      end

      payload
    end

    def send_request(api_url, payload)
      base_url = extract_base_url(api_url)

      conn = Faraday.new(url: base_url) do |f|
        f.request :multipart
        f.request :url_encoded
        f.adapter Faraday.default_adapter
      end

      path = extract_path(api_url)
      
      form_data = {
        student_id: payload[:student_id]
      }
      
      payload[:files].each do |file|
        form_data[:files] ||= []
        form_data[:files] << Faraday::UploadIO.new(file.path, 'image/jpeg')
      end

      conn.post(path, form_data)
    end
    
    def build_api_url(path)
      base_url = ENV['FACE_AUTH_API_URL']
      raise ArgumentError, 'FACE_AUTH_API_URL environment variable is not set' unless base_url.present?

      base_url = base_url.strip
      base_url = "http://#{base_url}" unless base_url.start_with?('http://', 'https://')

      "#{base_url}#{path}"
    end

    def extract_base_url(full_url)
      uri = URI.parse(full_url)
      "#{uri.scheme}://#{uri.host}:#{uri.port}"
    end

    def extract_path(full_url)
      URI.parse(full_url).path
    end
  end
end
