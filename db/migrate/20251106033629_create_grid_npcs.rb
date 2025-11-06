class CreateGridNpcs < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_npcs do |t|
      t.string :name
      t.text :description
      t.integer :grid_room_id
      t.string :npc_type
      t.json :dialogue_tree
      t.integer :grid_faction_id

      t.timestamps
    end
  end
end
