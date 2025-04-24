class AddUserToStudents < ActiveRecord::Migration[8.0]
  def change
    add_reference :students, :user, foreign_key: true, type: :uuid, null: true
  end
end
