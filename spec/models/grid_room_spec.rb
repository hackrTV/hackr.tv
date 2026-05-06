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
#  room_type           :string           default("standard"), not null
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
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone, room_type: "den") }
  let(:fixture_def) { create(:grid_item_definition, :fixture, properties: {"storage_capacity" => 8}) }
  let(:fixture_def_16) { create(:grid_item_definition, :fixture, properties: {"storage_capacity" => 16}) }
  let(:tool_def) { create(:grid_item_definition, item_type: "tool") }

  describe "#den_floor_items / #den_floor_count" do
    it "counts non-fixture items on the floor" do
      create(:grid_item, room: room, grid_hackr: nil, grid_item_definition: tool_def)
      create(:grid_item, room: room, grid_hackr: nil, grid_item_definition: tool_def)

      expect(room.den_floor_count).to eq(2)
    end

    it "excludes placed fixtures" do
      create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      create(:grid_item, room: room, grid_hackr: nil, grid_item_definition: tool_def)

      expect(room.den_floor_count).to eq(1)
    end

    it "excludes items stored in fixtures" do
      fixture = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      create(:grid_item, container: fixture, room: nil, grid_hackr: nil, grid_item_definition: tool_def)

      expect(room.den_floor_count).to eq(0)
    end
  end

  describe "#placed_fixtures" do
    it "returns only fixture items placed in the room" do
      fixture = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      create(:grid_item, room: room, grid_hackr: nil, grid_item_definition: tool_def)

      expect(room.placed_fixtures).to eq([fixture])
    end

    it "returns empty when no fixtures placed" do
      expect(room.placed_fixtures).to be_empty
    end
  end

  describe "#den_fixture_capacity" do
    it "sums storage_capacity of all placed fixtures" do
      create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def_16)

      expect(room.den_fixture_capacity).to eq(24)
    end

    it "returns 0 with no fixtures" do
      expect(room.den_fixture_capacity).to eq(0)
    end
  end

  describe "#den_stored_in_fixtures_count" do
    it "counts items stored across all placed fixtures" do
      f1 = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      f2 = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def_16)
      create(:grid_item, container: f1, room: nil, grid_hackr: nil, grid_item_definition: tool_def)
      create(:grid_item, container: f1, room: nil, grid_hackr: nil, grid_item_definition: tool_def)
      create(:grid_item, container: f2, room: nil, grid_hackr: nil, grid_item_definition: tool_def)

      expect(room.den_stored_in_fixtures_count).to eq(3)
    end

    it "returns 0 with no fixtures" do
      expect(room.den_stored_in_fixtures_count).to eq(0)
    end

    it "returns 0 with empty fixtures" do
      create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)

      expect(room.den_stored_in_fixtures_count).to eq(0)
    end
  end
end
