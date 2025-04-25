class AddPeriodCollumnForClassRoom < ActiveRecord::Migration[8.0]
  def change
    add_column :class_rooms, :period, :integer, null: false
  end
end
