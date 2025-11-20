class GridZone < ApplicationRecord
  belongs_to :grid_faction, optional: true
  belongs_to :ambient_playlist, class_name: "ZonePlaylist", optional: true

  has_many :grid_rooms

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :zone_type, inclusion: {
    in: %w[faction_base govcorp residential transit special],
    allow_nil: true
  }
end
