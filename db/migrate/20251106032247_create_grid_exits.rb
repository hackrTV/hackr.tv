class CreateGridExits < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_exits do |t|
      t.integer :from_room_id
      t.integer :to_room_id
      t.string :direction
      t.boolean :locked
      t.integer :requires_item_id

      t.timestamps
    end
    add_index :grid_exits, :from_room_id
    add_index :grid_exits, :to_room_id
  end
end
