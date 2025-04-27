# frozen_string_literal: true

module ImportStudent
  class ImportXlsx
    def initialize(file_path, class_room_id)
      @file_path = file_path
      @class_room_id = class_room_id
      @students = []
      @errors = []
    end

    attr_reader :students, :errors

    def call
      spreadsheet = Roo::Excelx.new(@file_path)
      header = spreadsheet.row(1).map(&:downcase)

      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]
        process_row(row.symbolize_keys)
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
