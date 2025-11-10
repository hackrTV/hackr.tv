class CreateAlbums < ActiveRecord::Migration[8.1]
  def change
    create_table :albums do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :album_type
      t.date :release_date
      t.text :description
      t.references :artist, null: false, foreign_key: true

      t.timestamps
    end

    add_index :albums, [:artist_id, :slug], unique: true
  end
end
