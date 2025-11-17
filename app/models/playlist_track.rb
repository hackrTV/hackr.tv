class PlaylistTrack < ApplicationRecord
  belongs_to :playlist
  belongs_to :track

  validates :track_id, uniqueness: {scope: :playlist_id, message: "is already in this playlist"}
  validates :position, presence: true, numericality: {only_integer: true, greater_than: 0}

  before_validation :set_position, on: :create

  private

  def set_position
    return if position.present?

    max_position = playlist.playlist_tracks.maximum(:position) || 0
    self.position = max_position + 1
  end
end
