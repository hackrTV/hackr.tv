class Artist < ApplicationRecord
  ARTIST_TYPES = %w[band ost voiceover].freeze

  has_many :albums, dependent: :destroy
  has_many :tracks, dependent: :destroy
  has_many :hackr_streams, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :artist_type, presence: true, inclusion: {in: ARTIST_TYPES}

  scope :bands, -> { where(artist_type: "band") }
  scope :osts, -> { where(artist_type: "ost") }
  scope :voiceovers, -> { where(artist_type: "voiceover") }

  def to_param
    slug
  end
end
