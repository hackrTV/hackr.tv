# == Schema Information
#
# Table name: zone_playlist_tracks
# Database name: primary
#
#  id               :integer          not null, primary key
#  position         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  track_id         :integer          not null
#  zone_playlist_id :integer          not null
#
# Indexes
#
#  index_zone_playlist_tracks_on_playlist_and_track  (zone_playlist_id,track_id) UNIQUE
#  index_zone_playlist_tracks_on_track_id            (track_id)
#  index_zone_playlist_tracks_on_zone_playlist_id    (zone_playlist_id)
#
# Foreign Keys
#
#  track_id          (track_id => tracks.id)
#  zone_playlist_id  (zone_playlist_id => zone_playlists.id)
#
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
