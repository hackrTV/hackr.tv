class ZonePlaylist < ApplicationRecord
  has_many :zone_playlist_tracks, dependent: :destroy
  has_many :tracks, through: :zone_playlist_tracks

  has_many :grid_zones, foreign_key: :ambient_playlist_id, dependent: :nullify
  has_many :grid_rooms, foreign_key: :ambient_playlist_id, dependent: :nullify

  validates :name, presence: true
  validates :crossfade_duration_ms, presence: true, numericality: {greater_than: 0}
  validates :default_volume, presence: true, numericality: {greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0}

  # Get tracks ordered by position
  def ordered_tracks
    tracks.order("zone_playlist_tracks.position ASC")
  end

  # Get next available position for new tracks
  def next_position
    (zone_playlist_tracks.maximum(:position) || 0) + 1
  end
end
