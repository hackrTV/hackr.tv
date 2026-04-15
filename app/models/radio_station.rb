# == Schema Information
#
# Table name: radio_stations
# Database name: primary
#
#  id          :integer          not null, primary key
#  color       :string
#  description :text
#  genre       :string
#  hidden      :boolean          default(FALSE), not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  slug        :string           not null
#  stream_url  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_radio_stations_on_position  (position)
#  index_radio_stations_on_slug      (slug) UNIQUE
#
class RadioStation < ApplicationRecord
  # Associations
  has_many :radio_station_playlists, -> { order(position: :asc) }, dependent: :destroy
  has_many :playlists, through: :radio_station_playlists
  has_many :hackr_radio_tunes, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :position, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  # Scopes
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :visible, -> { where(hidden: false) }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
