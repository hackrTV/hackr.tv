class CreateGridSalvageYields < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_salvage_yields do |t|
      t.references :source_definition, null: false, foreign_key: {to_table: :grid_item_definitions}
      t.references :output_definition, null: false, foreign_key: {to_table: :grid_item_definitions}
      t.integer :quantity, null: false, default: 1
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :grid_salvage_yields, [:source_definition_id, :output_definition_id],
      unique: true, name: "index_grid_salvage_yields_unique"
  end
end
