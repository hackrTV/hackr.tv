class CreateGridRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_rooms do |t|
      t.string :name
      t.text :description
      t.integer :grid_zone_id, null: false
      t.string :room_type

      t.timestamps
    end
    add_index :grid_rooms, :grid_zone_id
  end
end
