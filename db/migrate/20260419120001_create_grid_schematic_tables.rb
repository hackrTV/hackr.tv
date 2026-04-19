# frozen_string_literal: true

class CreateGridSchematicTables < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_schematics do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.references :output_definition, null: false, foreign_key: {to_table: :grid_item_definitions}
      t.integer :output_quantity, null: false, default: 1
      t.integer :xp_reward, null: false, default: 0
      t.integer :required_clearance, null: false, default: 0
      t.boolean :published, null: false, default: false
      t.integer :position, null: false, default: 0
      # Visibility gates (all nullable = not required)
      t.string :required_mission_slug
      t.string :required_achievement_slug
      # Future-proofing: room-type restriction (not enforced in v1)
      t.string :required_room_type
      t.timestamps
    end
    add_index :grid_schematics, :slug, unique: true

    create_table :grid_schematic_ingredients do |t|
      t.references :grid_schematic, null: false, foreign_key: true, index: true
      t.references :input_definition, null: false, foreign_key: {to_table: :grid_item_definitions}
      t.integer :quantity, null: false, default: 1
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grid_schematic_ingredients,
      [:grid_schematic_id, :input_definition_id],
      unique: true, name: :index_grid_schematic_ingredients_unique
  end
end
