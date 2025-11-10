class Album < ApplicationRecord
  belongs_to :artist
  has_many :tracks, -> { order(:track_number, :title) }, dependent: :restrict_with_error
  has_one_attached :cover_image

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: {scope: :artist_id}

  def to_param
    slug
  end
end
