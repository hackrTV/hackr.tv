class Track < ApplicationRecord
  belongs_to :artist
  belongs_to :album
  has_one_attached :audio_file
  has_many :playlist_tracks, dependent: :destroy
  has_many :playlists, through: :playlist_tracks
  has_many :zone_playlist_tracks, dependent: :destroy
  has_many :zone_playlists, through: :zone_playlist_tracks

  # Serialize JSON fields
  serialize :streaming_links, coder: JSON
  serialize :videos, coder: JSON

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: {scope: :artist_id}

  # Scopes matching Sinatra logic
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(Arel.sql("CASE WHEN featured THEN 1 ELSE 0 END DESC, release_date DESC NULLS LAST")) }
  scope :album_order, -> { order(:track_number, :title) }
  scope :visible_in_pulse_vault, -> { where(show_in_pulse_vault: true) }

  def to_param
    slug
  end
end
