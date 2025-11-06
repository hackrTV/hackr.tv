class GridFaction < ApplicationRecord
  belongs_to :artist, optional: true

  has_many :grid_zones
  has_many :grid_rooms, through: :grid_zones
  has_many :grid_mobs

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
