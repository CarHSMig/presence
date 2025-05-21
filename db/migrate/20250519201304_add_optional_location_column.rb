class AddOptionalLocationColumn < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :location_optional, :boolean, default: true, null: false
  end
end
