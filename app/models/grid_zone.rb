# == Schema Information
#
# Table name: grid_zones
# Database name: primary
#
#  id                  :integer          not null, primary key
#  danger_level        :integer          default(0), not null
#  description         :text
#  name                :string
#  slug                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ambient_playlist_id :integer
#  grid_faction_id     :integer
#  grid_region_id      :integer
#
# Indexes
#
#  index_grid_zones_on_ambient_playlist_id  (ambient_playlist_id)
#  index_grid_zones_on_grid_faction_id      (grid_faction_id)
#  index_grid_zones_on_grid_region_id       (grid_region_id)
#  index_grid_zones_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  ambient_playlist_id  (ambient_playlist_id => zone_playlists.id)
#  grid_region_id       (grid_region_id => grid_regions.id)
#
class GridZone < ApplicationRecord
  has_paper_trail

  belongs_to :grid_region
  belongs_to :grid_faction, optional: true
  belongs_to :ambient_playlist, class_name: "ZonePlaylist", optional: true

  has_many :grid_rooms

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :danger_level, numericality: {only_integer: true, in: 0..10}

  after_commit :bust_zone_map_cache, if: :zone_map_relevant_change?

  private

  def zone_map_relevant_change?
    saved_change_to_name? || saved_change_to_slug? || saved_change_to_danger_level? ||
      saved_change_to_grid_faction_id? || saved_change_to_grid_region_id? ||
      previously_new_record?
  end

  def bust_zone_map_cache
    Grid::ZoneMapBuilder.bust_cache!(id)
  end
end
