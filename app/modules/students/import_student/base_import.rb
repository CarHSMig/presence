# frozen_string_literal: true

module Students
  module ImportStudent
    class BaseImport
      def initialize(file_path, class_room_id)
        @file_path = file_path
        @class_room_id = class_room_id
        @students = []
        @errors = []
      end

      attr_reader :students, :errors

      def call
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
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
end
