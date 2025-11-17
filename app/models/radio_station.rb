class RadioStation < ApplicationRecord
  # Associations
  has_many :radio_station_playlists, -> { order(position: :asc) }, dependent: :destroy
  has_many :playlists, through: :radio_station_playlists

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :position, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  # Scopes
  scope :ordered, -> { order(position: :asc, name: :asc) }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
