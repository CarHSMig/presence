# frozen_string_literal: true

require 'httparty'

module FaceAuth
  class DeleteEmbedding
    include HTTParty

    def initialize(embedding_id)
      @embedding_id = embedding_id
    end

    def delete_embedding
      unless @embedding_id.present?
        raise ArgumentError, 'Embedding ID is required'
      end

      api_url = build_api_url("/embeddings/#{@embedding_id}")

      response = HTTParty.delete(api_url)

      unless response.success?
        Rails.logger.error("Delete embedding API error: HTTP #{response.code} - #{response.body}")
        return false
      end

      true
    rescue ArgumentError => e
      Rails.logger.error("Error deleting embedding: #{e.message}")
      false
    rescue StandardError => e
      Rails.logger.error("Unexpected error in delete embedding: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      false
    end

    def perform
      delete_embedding
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

