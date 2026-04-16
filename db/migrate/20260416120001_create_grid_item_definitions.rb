class CreateGridItemDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_item_definitions do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.string :item_type, null: false
      t.string :rarity, null: false
      t.integer :value, null: false, default: 0
      t.json :properties, null: false, default: {}
      t.timestamps
    end

    add_index :grid_item_definitions, :slug, unique: true
    add_index :grid_item_definitions, :item_type
  end
end
