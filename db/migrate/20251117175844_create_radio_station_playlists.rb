class CreateRadioStationPlaylists < ActiveRecord::Migration[8.1]
  def change
    create_table :radio_station_playlists do |t|
      t.references :radio_station, null: false, foreign_key: true
      t.references :playlist, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :radio_station_playlists, [:radio_station_id, :playlist_id], unique: true, name: 'index_radio_station_playlists_unique'
    add_index :radio_station_playlists, [:radio_station_id, :position], name: 'index_radio_station_playlists_position'
  end
end
