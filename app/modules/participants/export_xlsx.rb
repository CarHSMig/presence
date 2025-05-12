module Participants
  class ExportXlsx < BaseExport
    require 'axlsx'

    def call
      package = Axlsx::Package.new
      workbook = package.workbook

      workbook.add_worksheet(name: 'Participantes') do |sheet|
        header_style = workbook.styles.add_style(
          bg_color: 'C5343A',
          fg_color: 'FFFFFF',
          b: true,
          alignment: { horizontal: :center }
        )

        even_row_style = workbook.styles.add_style(
          bg_color: 'FFF0F0'
        )

        sheet.add_row headers, style: header_style

        @participants.each_with_index do |participant, index|
          style = index.even? ? even_row_style : nil
          sheet.add_row [
            participant.student.name,
            participant.present ? 'Sim' : 'Não',
            format_location(participant.location),
            participant.updated_at.strftime('%d/%m/%Y %H:%M')
          ], style: style
        end
      end

      package.to_stream.read
    end
  end
end
