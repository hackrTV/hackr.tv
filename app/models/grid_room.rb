class GridRoom < ApplicationRecord
  belongs_to :grid_zone

  has_many :exits_from, class_name: "GridExit", foreign_key: :from_room_id, dependent: :destroy
  has_many :exits_to, class_name: "GridExit", foreign_key: :to_room_id, dependent: :destroy
  has_many :grid_items, foreign_key: :room_id
  has_many :grid_npcs
  has_many :grid_hackrs, foreign_key: :current_room_id

  validates :name, presence: true
  validates :room_type, inclusion: {
    in: %w[hub faction_base govcorp special safe_zone transit shop danger_zone prism dream],
    allow_nil: true
  }

  # Delegate to zone for convenience
  delegate :faction, :color_scheme, to: :grid_zone
end
