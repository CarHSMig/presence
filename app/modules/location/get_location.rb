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

      formated_location = location.gsub(',', '').strip
      
      response = HTTParty.get(
        'https://nominatim.openstreetmap.org/search',
        query: {
          q: formated_location,
          format: 'json',
          limit: 1,
          addressdetails: ''
        },
        headers: {
          'User-Agent' => 'carloshenriquedossantosmigon@gmail.com'
        }
      )
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