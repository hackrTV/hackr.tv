# == Schema Information
#
# Table name: albums
# Database name: primary
#
#  id           :integer          not null, primary key
#  album_type   :string
#  description  :text
#  name         :string           not null
#  release_date :date
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer          not null
#
# Indexes
#
#  index_albums_on_artist_id           (artist_id)
#  index_albums_on_artist_id_and_slug  (artist_id,slug) UNIQUE
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
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
