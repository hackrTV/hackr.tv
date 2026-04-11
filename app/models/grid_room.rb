# == Schema Information
#
# Table name: grid_rooms
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  min_clearance       :integer          default(0), not null
#  name                :string
#  room_type           :string
#  slug                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ambient_playlist_id :integer
#  grid_zone_id        :integer          not null
#
# Indexes
#
#  index_grid_rooms_on_ambient_playlist_id  (ambient_playlist_id)
#  index_grid_rooms_on_grid_zone_id         (grid_zone_id)
#  index_grid_rooms_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  ambient_playlist_id  (ambient_playlist_id => zone_playlists.id)
#
class GridRoom < ApplicationRecord
  belongs_to :grid_zone
  belongs_to :ambient_playlist, class_name: "ZonePlaylist", optional: true

  has_many :exits_from, class_name: "GridExit", foreign_key: :from_room_id, dependent: :destroy
  has_many :exits_to, class_name: "GridExit", foreign_key: :to_room_id, dependent: :destroy
  has_many :grid_items, foreign_key: :room_id
  has_many :grid_mobs
  has_many :grid_hackrs, foreign_key: :current_room_id

  validates :name, presence: true
  validates :room_type, inclusion: {
    in: %w[hub faction_base govcorp special safe_zone transit shop danger_zone prism dream],
    allow_nil: true
  }
  validates :min_clearance, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  # Delegate to zone for convenience
  delegate :faction, :color_scheme, to: :grid_zone

  def clearance_gated?
    min_clearance > 0
  end
end
