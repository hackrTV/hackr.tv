class CreateGridRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_rooms do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.integer :grid_zone_id, null: false
      t.string :room_type

      t.timestamps
    end
    add_index :grid_rooms, :grid_zone_id
    add_index :grid_rooms, :slug, unique: true
  end
end
