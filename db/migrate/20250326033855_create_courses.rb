class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses, id: :uuid do |t|
      t.string :name, null: false
      t.integer :periods, null: false

      t.timestamps
    end
  end
end
