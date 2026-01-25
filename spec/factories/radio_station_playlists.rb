# == Schema Information
#
# Table name: radio_station_playlists
# Database name: primary
#
#  id               :integer          not null, primary key
#  position         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  playlist_id      :integer          not null
#  radio_station_id :integer          not null
#
# Indexes
#
#  index_radio_station_playlists_on_playlist_id       (playlist_id)
#  index_radio_station_playlists_on_radio_station_id  (radio_station_id)
#  index_radio_station_playlists_position             (radio_station_id,position)
#  index_radio_station_playlists_unique               (radio_station_id,playlist_id) UNIQUE
#
# Foreign Keys
#
#  playlist_id       (playlist_id => playlists.id)
#  radio_station_id  (radio_station_id => radio_stations.id)
#
FactoryBot.define do
  factory :radio_station_playlist do
    association :radio_station
    association :playlist
    # Let the callback assign position automatically (don't set it here)
  end
end
