# == Schema Information
#
# Table name: grid_zones
# Database name: primary
#
#  id                  :integer          not null, primary key
#  color_scheme        :string
#  description         :text
#  name                :string
#  slug                :string
#  zone_type           :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ambient_playlist_id :integer
#  grid_faction_id     :integer
#
# Indexes
#
#  index_grid_zones_on_ambient_playlist_id  (ambient_playlist_id)
#
# Foreign Keys
#
#  ambient_playlist_id  (ambient_playlist_id => zone_playlists.id)
#
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
