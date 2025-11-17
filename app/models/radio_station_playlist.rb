class RadioStationPlaylist < ApplicationRecord
  belongs_to :radio_station
  belongs_to :playlist

  # Validations
  validates :position, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :playlist_id, uniqueness: {scope: :radio_station_id, message: "is already in this radio station"}

  # Callbacks
  before_validation :set_position, if: -> { position.nil? }

  private

  def set_position
    max_position = radio_station.radio_station_playlists.maximum(:position) || -1
    self.position = max_position + 1
  end
end
