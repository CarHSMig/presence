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
  end
end
