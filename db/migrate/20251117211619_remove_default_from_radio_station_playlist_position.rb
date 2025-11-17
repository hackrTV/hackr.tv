class RemoveDefaultFromRadioStationPlaylistPosition < ActiveRecord::Migration[8.1]
  def change
    change_column_default :radio_station_playlists, :position, from: 0, to: nil
  end
end
