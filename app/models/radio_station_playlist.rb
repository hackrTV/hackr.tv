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
class RadioStationPlaylist < ApplicationRecord
  belongs_to :radio_station
  belongs_to :playlist

  # Validations
  validates :position, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :playlist_id, uniqueness: {scope: :radio_station_id, message: "is already in this radio station"}

  # Callbacks
  before_validation :set_position, if: -> { position.nil? }

  private

  def set_position
    max_position = RadioStationPlaylist.where(radio_station_id: radio_station_id).maximum(:position) || 0
    self.position = max_position + 1
  end
end
