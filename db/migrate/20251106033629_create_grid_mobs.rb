class CreateGridMobs < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_mobs do |t|
      t.string :name
      t.text :description
      t.integer :grid_room_id
      t.string :mob_type
      t.json :dialogue_tree
      t.integer :grid_faction_id

      t.timestamps
    end
  end
end
