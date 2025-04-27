# frozen_string_literal: true

require 'csv'

module ImportStudent
  class ImportCsv
    def initialize(file_path, class_room_id)
      @file_path = file_path
      @class_room_id = class_room_id
      @students = []
      @errors = []
    end

    attr_reader :students, :errors

    def call
      CSV.foreach(@file_path, headers: true, header_converters: :symbol) do |row|
        process_row(row.to_hash)
      end

      { students: students, errors: errors }
    end

    private

    def process_row(row)
      params = {
        name: row[:nome],
        ra: row[:ra],
        email: row[:email],
        class_room_id: @class_room_id
      }

      begin
        student = StudentManagement::Create.new(params).call
        students << student
      rescue ActiveRecord::RecordInvalid => e
        errors << { attributes: params.except(:class_room_id), error: e.message }
      end
    end
  end
end