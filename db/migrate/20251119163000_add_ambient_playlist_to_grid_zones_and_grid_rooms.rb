class AddAmbientPlaylistToGridZonesAndGridRooms < ActiveRecord::Migration[8.1]
  def change
    add_reference :grid_zones, :ambient_playlist, null: true, foreign_key: {to_table: :zone_playlists}
    add_reference :grid_rooms, :ambient_playlist, null: true, foreign_key: {to_table: :zone_playlists}
  end
end
