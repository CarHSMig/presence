class AddFaceAuthColumnToEvent < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :face_auth, :boolean, default: false
  end
end
