# frozen_string_literal: true

module StudentManagement
  class ImportDispatcher
    def initialize(file_path, class_room_id)
      @file_path = file_path
      @class_room_id = class_room_id
    end

    def call
      case File.extname(@file_path).downcase
      when '.xlsx'
        byebug
        ImportStudent::ImportXlsx.new(@file_path, @class_room_id).call
      when '.csv'
        ImportStudent::ImportCsv.new(@file_path, @class_room_id).call
      else
        raise StandardError, 'Formato de arquivo não suportado. Envie um arquivo .xlsx ou .csv'
      end
    end
  end
end
