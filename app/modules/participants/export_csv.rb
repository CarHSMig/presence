module Participants
  class ExportCsv < BaseExport
    require 'csv'

    def call
      CSV.generate(col_sep: ';', encoding: 'UTF-8') do |csv|
        csv << headers
        @participants.each do |participant|
          csv << [
            participant.student.name,
            participant.present ? 'Sim' : 'Não',
            participant.location,
            participant.updated_at.strftime('%d/%m/%Y %H:%M')
          ]
        end
      end
    end
  end
end
