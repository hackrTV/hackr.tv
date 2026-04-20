class AddDenFieldsToGridRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_rooms, :owner_id, :integer
    add_column :grid_rooms, :locked, :boolean, default: false, null: false

    add_index :grid_rooms, :owner_id, unique: true
    add_foreign_key :grid_rooms, :grid_hackrs, column: :owner_id
  end
end
