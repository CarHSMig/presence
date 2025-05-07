class CreateJoinTableEventsCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses_events, id: false do |t|
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.references :course, null: false, foreign_key: true, type: :uuid

      # Índices para melhorar consultas
      t.index [:event_id, :course_id], unique: true
      t.index [:course_id, :event_id]
    end
  end
end
