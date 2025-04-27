# frozen_string_literal: true

require 'csv'

module ImportStudent
  class ImportCsv < BaseImport
    def call
      CSV.foreach(@file_path, headers: true, header_converters: :symbol) do |row|
        process_row(row.to_hash)
      end

      { students: students, errors: errors }
    end
  end
end