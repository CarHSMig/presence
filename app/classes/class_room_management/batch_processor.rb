# frozen_string_literal: true

module ClassRoomManagement
  class BatchProcessor
    attr_reader :course_id, :results

    def initialize(course_id)
      @course_id = course_id
      @results = { success: [], errors: [] }
    end

    def process(operations)
      ActiveRecord::Base.transaction do
        operations.each do |operation|
          process_operation(operation)
        end

        raise ActiveRecord::Rollback if results[:errors].any?
      end

      results
    end

    private

    def process_operation(operation)
      case operation[:action]
      when 'create'
        handle_create(operation)
      when 'update'
        handle_update(operation)
      when 'delete'
        handle_delete(operation)
      else
        results[:errors] << { operation: operation, error: 'Ação inválida' }
      end
    end

    def handle_create(operation)
      attributes = operation[:attributes] || {}
      class_room = ClassRoom.new(attributes.merge(course_id: course_id))
      
      if validate_class_room_period(class_room)
        results[:errors] << { operation: operation, error: 'Período inválido' }
        return
      end

      if class_room.save
        results[:success] << { id: class_room.id, action: 'create', status: 'success' }
      else
        results[:errors] << { operation: operation, errors: class_room.errors.full_messages }
      end
    end

    def handle_update(operation)
      class_room = ClassRoom.find_by(id: operation[:id])
      
      unless class_room
        results[:errors] << { operation: operation, error: 'Turma não encontrada' }
        return
      end

      if validate_class_room_period(class_room)
        results[:errors] << { operation: operation, error: 'Período inválido' }
        return
      end

      if class_room.update(operation[:attributes] || {})
        results[:success] << { id: class_room.id, action: 'update', status: 'success' }
      else
        results[:errors] << { operation: operation, errors: class_room.errors.full_messages }
      end
    end

    def handle_delete(operation)
      class_room = ClassRoom.find_by(id: operation[:id])
      
      unless class_room
        results[:errors] << { operation: operation, error: 'Turma não encontrada' }
        return
      end

      if class_room.destroy
        results[:success] << { id: class_room.id, action: 'delete', status: 'success' }
      else
        results[:errors] << { operation: operation, errors: class_room.errors.full_messages }
      end
    end

    def validate_class_room_period(class_room)
      course = class_room.course
      return false unless course

      course.periods < class_room.period
    end
  end
end 