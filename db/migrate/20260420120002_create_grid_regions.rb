class CreateGridRegions < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_regions do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :grid_regions, :slug, unique: true

    add_reference :grid_zones, :grid_region, foreign_key: true, index: true
  end
end
