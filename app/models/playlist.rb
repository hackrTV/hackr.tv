class Playlist < ApplicationRecord
  belongs_to :grid_hackr
  has_many :playlist_tracks, -> { order(position: :asc) }, dependent: :destroy
  has_many :tracks, through: :playlist_tracks
  has_many :radio_station_playlists, dependent: :destroy
  has_many :radio_stations, through: :radio_station_playlists

  validates :name, presence: true
  validates :share_token, presence: true, uniqueness: true

  before_validation :generate_share_token, on: :create

  default_scope { order(created_at: :desc) }

  def track_count
    playlist_tracks.count
  end

  private

  def generate_share_token
    self.share_token ||= SecureRandom.urlsafe_base64(16)
  end
end
