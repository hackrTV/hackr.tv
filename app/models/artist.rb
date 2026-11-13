# == Schema Information
#
# Table name: artists
# Database name: primary
#
#  id           :integer          not null, primary key
#  artist_type  :string           default("band"), not null
#  description  :text
#  genre        :string
#  name         :string
#  position     :integer
#  profile_path :string
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_artists_on_position  (position)
#  index_artists_on_slug      (slug) UNIQUE
#
class Artist < ApplicationRecord
  has_paper_trail

  ARTIST_TYPES = %w[band ost voiceover].freeze
  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  has_many :releases, dependent: :destroy
  has_many :tracks, dependent: :destroy
  has_many :hackr_streams, dependent: :destroy
  has_one_attached :avatar
  has_one_attached :hero_image

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :artist_type, presence: true, inclusion: {in: ARTIST_TYPES}
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validates :profile_path, format: {with: %r{\A/(?!/)\S*\z}}, allow_blank: true
  validate :images_are_images

  normalizes :profile_path, with: ->(path) { path.strip.presence }

  scope :bands, -> { where(artist_type: "band") }
  scope :ordered, -> { order(Arel.sql("artists.position IS NULL, artists.position, LOWER(artists.name), artists.id")) }
  scope :osts, -> { where(artist_type: "ost") }
  scope :voiceovers, -> { where(artist_type: "voiceover") }

  # The square avatar at the cover renditions (Release#cover_*): the
  # roster tile and admin ledger fall back to it when no release cover.
  def avatar_thumbnail
    avatar.variant(resize_to_fill: [80, 80], format: :jpeg, saver: {quality: 80})
  end

  def avatar_standard
    avatar.variant(resize_to_fill: [300, 300], format: :jpeg, saver: {quality: 85})
  end

  def avatar_large
    avatar.variant(resize_to_limit: [800, 800], format: :jpeg, saver: {quality: 85})
  end

  def hero_large
    hero_image.variant(resize_to_limit: [1600, 1600], format: :jpeg, saver: {quality: 85})
  end

  def to_param
    slug
  end

  private

  def images_are_images
    {avatar: avatar, hero_image: hero_image}.each do |name, image|
      next unless image.attached? && image.blob.new_record?
      errors.add(name, "must be a JPEG, PNG, or WebP image") unless IMAGE_CONTENT_TYPES.include?(image.blob.content_type)
    end
  end
end
