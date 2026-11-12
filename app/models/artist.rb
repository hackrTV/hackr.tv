# == Schema Information
#
# Table name: artists
# Database name: primary
#
#  id          :integer          not null, primary key
#  artist_type :string           default("band"), not null
#  genre       :string
#  name        :string
#  position    :integer
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_artists_on_position  (position)
#  index_artists_on_slug      (slug) UNIQUE
#
class Artist < ApplicationRecord
  has_paper_trail

  ARTIST_TYPES = %w[band ost voiceover].freeze

  has_many :releases, dependent: :destroy
  has_many :tracks, dependent: :destroy
  has_many :hackr_streams, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :artist_type, presence: true, inclusion: {in: ARTIST_TYPES}
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true

  scope :bands, -> { where(artist_type: "band") }
  scope :ordered, -> { order(Arel.sql("artists.position IS NULL, artists.position, LOWER(artists.name), artists.id")) }
  scope :osts, -> { where(artist_type: "ost") }
  scope :voiceovers, -> { where(artist_type: "voiceover") }

  def to_param
    slug
  end
end
