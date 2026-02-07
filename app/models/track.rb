# == Schema Information
#
# Table name: tracks
# Database name: primary
#
#  id                  :integer          not null, primary key
#  cover_image         :string
#  duration            :string
#  featured            :boolean          default(FALSE)
#  lyrics              :text
#  release_date        :date
#  show_in_pulse_vault :boolean          default(TRUE), not null
#  slug                :string
#  streaming_links     :text
#  title               :string
#  track_number        :integer
#  videos              :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  album_id            :integer          not null
#  artist_id           :integer          not null
#
# Indexes
#
#  index_tracks_on_album_id            (album_id)
#  index_tracks_on_artist_id           (artist_id)
#  index_tracks_on_artist_id_and_slug  (artist_id,slug) UNIQUE
#  index_tracks_on_featured            (featured)
#  index_tracks_on_release_date        (release_date)
#
# Foreign Keys
#
#  album_id   (album_id => albums.id)
#  artist_id  (artist_id => artists.id)
#
class Track < ApplicationRecord
  has_paper_trail

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
