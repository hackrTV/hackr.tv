class CreateTracks < ActiveRecord::Migration[8.0]
  def change
    create_table :tracks do |t|
      t.string :title
      t.string :slug
      t.references :artist, null: false, foreign_key: true
      t.string :album
      t.string :album_type
      t.date :release_date
      t.string :duration
      t.string :cover_image
      t.boolean :featured, default: false
      t.text :streaming_links
      t.text :videos
      t.text :lyrics

      t.timestamps
    end

    add_index :tracks, [ :artist_id, :slug ], unique: true
    add_index :tracks, :featured
    add_index :tracks, :release_date
  end
end
