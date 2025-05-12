# frozen_string_literal: true

module Students
  module ImportStudent
    class ImportTemplate
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def template
        format = params[:format].to_s.downcase

        case format
        when 'xlsx'
          generate_excel_template
        else
          generate_csv_template
        end
      end

      private

      def generate_csv_template
        headers = %w[nome ra email]

        CSV.generate(headers: true) do |csv|
          csv << headers
        end
      end

      def generate_excel_template
        package = Axlsx::Package.new
        workbook = package.workbook

        workbook.add_worksheet(name: 'Alunos') do |sheet|
          sheet.add_row %w[nome ra email]
        end

        temp_file = Tempfile.new(['template_importacao', '.xlsx'])
        package.serialize(temp_file.path)

        file_content = File.read(temp_file.path)
        temp_file.close
        temp_file.unlink

        file_content
      end
    end
  end
end