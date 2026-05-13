class CreateGridRoomVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_room_visits do |t|
      t.integer :grid_hackr_id, null: false
      t.integer :grid_room_id, null: false
      t.datetime :first_visited_at, null: false

      t.timestamps
    end

    add_index :grid_room_visits, :grid_hackr_id
    add_index :grid_room_visits, :grid_room_id
    add_index :grid_room_visits, [:grid_hackr_id, :grid_room_id],
      unique: true, name: "index_grid_room_visits_unique"

    add_foreign_key :grid_room_visits, :grid_hackrs, on_delete: :cascade
    add_foreign_key :grid_room_visits, :grid_rooms, on_delete: :cascade
  end
end
