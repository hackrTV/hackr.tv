class Track < ApplicationRecord
  belongs_to :artist
  belongs_to :album
  has_one_attached :audio_file

  # Serialize JSON fields
  serialize :streaming_links, coder: JSON
  serialize :videos, coder: JSON

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: {scope: :artist_id}

  # Scopes matching Sinatra logic
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(Arel.sql("CASE WHEN featured THEN 1 ELSE 0 END DESC, release_date DESC NULLS LAST")) }
  scope :album_order, -> { order(:track_number, :title) }

  def to_param
    slug
  end
end
