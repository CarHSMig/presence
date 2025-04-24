class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events, id: :uuid do |t|
      t.string :name, null: false
      t.string :description
      t.datetime :event_start, null: false
      t.datetime :event_end, null: false
      t.references :course, null: false, foreign_key: { on_update: :cascade }, type: :uuid
      t.jsonb :location, default: {}, null: false

      t.timestamps
    end
  end
end
