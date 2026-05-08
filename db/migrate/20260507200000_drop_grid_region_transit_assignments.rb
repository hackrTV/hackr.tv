# frozen_string_literal: true

class DropGridRegionTransitAssignments < ActiveRecord::Migration[8.0]
  def up
    drop_table :grid_region_transit_assignments
  end

  def down
    create_table :grid_region_transit_assignments do |t|
      t.references :grid_region, null: false, foreign_key: {on_delete: :cascade}
      t.references :grid_transit_type, null: false, foreign_key: {on_delete: :cascade}
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grid_region_transit_assignments, [:grid_region_id, :grid_transit_type_id],
      unique: true, name: "index_region_transit_assignments_unique"
  end
end
