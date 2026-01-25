# == Schema Information
#
# Table name: playlists
# Database name: primary
#
#  id            :integer          not null, primary key
#  description   :text
#  is_public     :boolean          default(FALSE), not null
#  name          :string           not null
#  share_token   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_playlists_on_grid_hackr_id  (grid_hackr_id)
#  index_playlists_on_share_token    (share_token) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
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
