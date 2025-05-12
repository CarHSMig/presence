# frozen_string_literal: true

module Students
  module ImportStudent
    class ImportXlsx < BaseImport
      def call
        spreadsheet = Roo::Excelx.new(@file_path)
        header = spreadsheet.row(1).map(&:downcase)

        (2..spreadsheet.last_row).each do |i|
          row = Hash[[header, spreadsheet.row(i)].transpose]
          process_row(row.symbolize_keys)
        end

        { students: students, errors: errors }
      end
    end
  end
end