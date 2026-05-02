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
#  index_grid_zones_on_grid_region_id       (grid_region_id)
#
# Foreign Keys
#
#  ambient_playlist_id  (ambient_playlist_id => zone_playlists.id)
#  grid_region_id       (grid_region_id => grid_regions.id)
#
require "rails_helper"

RSpec.describe GridZone, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
