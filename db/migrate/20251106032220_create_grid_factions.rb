class CreateGridFactions < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_factions do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :color_scheme
      t.integer :artist_id

      t.timestamps
    end
  end
end
