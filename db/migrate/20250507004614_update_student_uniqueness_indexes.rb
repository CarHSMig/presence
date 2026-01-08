class UpdateStudentUniquenessIndexes < ActiveRecord::Migration[7.0]
  def change
    remove_index :students, :name if index_exists?(:students, :name)
    remove_index :students, :ra if index_exists?(:students, :ra)

    add_index :students, [:name, :class_room_id], unique: true
    add_index :students, [:ra, :class_room_id], unique: true
  end
end 