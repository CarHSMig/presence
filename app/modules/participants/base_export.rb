module Participants
  class BaseExport
    def initialize(participants)
      @participants = participants
    end

    def call
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def headers
      ['Nome', 'Presente', 'Localização', 'Horário da Presença']
    end

    protected

    def format_location(location)
      return '' unless location.is_a?(Hash)

      location_parts = []

      location_parts << location['road'] if location['road'].present?
      location_parts << location['amenity'] if location['amenity'].present?
      location_parts << location['town'] if location['town'].present?
      location_parts << location['state'] if location['state'].present?
      location_parts << location['country'] if location['country'].present?

      location_parts.join(', ')
    end
  end
end
