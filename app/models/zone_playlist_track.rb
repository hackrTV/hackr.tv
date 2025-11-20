class ZonePlaylistTrack < ApplicationRecord
  belongs_to :zone_playlist
  belongs_to :track

  validates :position, presence: true, numericality: {greater_than: 0}
  validates :track_id, uniqueness: {scope: :zone_playlist_id, message: "is already in this playlist"}

  before_validation :set_position, on: :create

  # Remove gaps in positions after deletion
  after_destroy :reorder_positions

  private

  def set_position
    self.position ||= zone_playlist.next_position
  end

  def reorder_positions
    # Get all remaining tracks for this playlist ordered by position
    remaining_tracks = zone_playlist.zone_playlist_tracks.order(:position)

    # Reassign positions sequentially
    remaining_tracks.each_with_index do |track, index|
      track.update_column(:position, index + 1)
    end
  end
end
