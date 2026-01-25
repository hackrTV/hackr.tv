# == Schema Information
#
# Table name: playlist_tracks
# Database name: primary
#
#  id          :integer          not null, primary key
#  position    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  playlist_id :integer          not null
#  track_id    :integer          not null
#
# Indexes
#
#  index_playlist_tracks_on_playlist_id               (playlist_id)
#  index_playlist_tracks_on_playlist_id_and_position  (playlist_id,position)
#  index_playlist_tracks_on_playlist_id_and_track_id  (playlist_id,track_id) UNIQUE
#  index_playlist_tracks_on_track_id                  (track_id)
#
# Foreign Keys
#
#  playlist_id  (playlist_id => playlists.id)
#  track_id     (track_id => tracks.id)
#
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
