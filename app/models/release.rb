# == Schema Information
#
# Table name: releases
# Database name: primary
#
#  id              :integer          not null, primary key
#  catalog_number  :string
#  classification  :string
#  coming_soon     :boolean          default(FALSE), not null
#  credits         :text
#  description     :text
#  label           :string
#  media_format    :string
#  name            :string           not null
#  notes           :text
#  release_date    :date
#  release_type    :string
#  slug            :string           not null
#  streaming_links :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  artist_id       :integer          not null
#
# Indexes
#
#  index_releases_on_artist_id           (artist_id)
#  index_releases_on_artist_id_and_slug  (artist_id,slug) UNIQUE
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
class Release < ApplicationRecord
  has_paper_trail

  belongs_to :artist
  has_many :tracks, -> { order(:track_number, :title) }, dependent: :restrict_with_error
  has_one_attached :cover_image

  def cover_thumbnail
    cover_image.variant(resize_to_fill: [80, 80], format: :jpeg, saver: {quality: 80})
  end

  def cover_standard
    cover_image.variant(resize_to_fill: [300, 300], format: :jpeg, saver: {quality: 85})
  end

  serialize :streaming_links, coder: JSON

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: {scope: :artist_id}

  scope :released, -> { where(coming_soon: false) }

  # The catalog's released list for one artist (ArtistCatalogController
  # #releases, the XERAEN console's status block): newest first, and a
  # release whose tracks are all hidden from the Pulse Vault stays out.
  # Returns an Array (the reject needs the tracks).
  def self.catalog_visible(artist)
    released.where(artist: artist)
      .order(Arel.sql("release_date DESC NULLS LAST"))
      .reject { |r| r.tracks.any? && r.tracks.where(show_in_pulse_vault: true).none? }
  end

  def to_param
    slug
  end
end
