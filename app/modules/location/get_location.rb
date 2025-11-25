require 'httparty'

module Location
  class GetLocation
    include HTTParty
    attr_reader :location

    def initialize(location)
      @location = location
    end

    def get_location
      raise ArgumentError, 'Latitude and longitude are required' unless location.present?

      serch_location = URI.encode_www_form_component(location)
      response = HTTParty.get("https://nominatim.openstreetmap.org/search?q=#{serch_location}&format=json&limit=1&addressdetails=", headers: { 'User-Agent' => 'carloshenriquedossantosmigon@gmail.com' })
      JSON.parse(response.body)
    end

    def perform
      get_location
    rescue ArgumentError => e
      Rails.logger.error("Error getting location: #{e.message}")
      nil
    end
  end
end