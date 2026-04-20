# == Schema Information
#
# Table name: grid_rooms
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  locked              :boolean          default(FALSE), not null
#  min_clearance       :integer          default(0), not null
#  name                :string
#  room_type           :string
#  slug                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ambient_playlist_id :integer
#  grid_zone_id        :integer          not null
#  owner_id            :integer
#
# Indexes
#
#  index_grid_rooms_on_ambient_playlist_id  (ambient_playlist_id)
#  index_grid_rooms_on_grid_zone_id         (grid_zone_id)
#  index_grid_rooms_on_owner_id             (owner_id) UNIQUE
#  index_grid_rooms_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  ambient_playlist_id  (ambient_playlist_id => zone_playlists.id)
#  owner_id             (owner_id => grid_hackrs.id)
#
require "rails_helper"

RSpec.describe GridRoom, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
