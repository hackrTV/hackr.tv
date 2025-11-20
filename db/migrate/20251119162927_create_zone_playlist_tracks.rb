class CreateZonePlaylistTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :zone_playlist_tracks do |t|
      t.references :zone_playlist, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end

    add_index :zone_playlist_tracks, [:zone_playlist_id, :track_id], unique: true, name: "index_zone_playlist_tracks_on_playlist_and_track"
  end
end
