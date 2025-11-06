class CreateGridZones < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_zones do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :zone_type
      t.string :color_scheme
      t.integer :grid_faction_id

      t.timestamps
    end
  end
end
