class CreateZonePlaylists < ActiveRecord::Migration[8.1]
  def change
    create_table :zone_playlists do |t|
      t.string :name, null: false
      t.string :slug
      t.text :description
      t.integer :crossfade_duration_ms, default: 5000, null: false
      t.decimal :default_volume, precision: 3, scale: 2, default: 0.35, null: false

      t.timestamps
    end
    add_index :zone_playlists, :slug, unique: true
  end
end
