class AddLatitudeAndLongitudeToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :latitude, :decimal, precision: 15, scale: 10, null: false
    add_column :events, :longitude, :decimal, precision: 15, scale: 10, null: false
  end
end
