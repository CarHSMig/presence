class AddUserToStudents < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :student, foreign_key: { on_update: :cascade, on_delete: :cascade }, type: :uuid, null: true
  end
end
