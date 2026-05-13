require "rails_helper"

RSpec.describe Grid::ZoneMapBuilder do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room_a) { create(:grid_room, :hub, grid_zone: zone) }
  let(:room_b) { create(:grid_room, grid_zone: zone) }
  let(:room_c) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room_a) }

  before do
    GridExit.create!(from_room: room_a, to_room: room_b, direction: "north")
    GridExit.create!(from_room: room_b, to_room: room_a, direction: "south")
    GridExit.create!(from_room: room_b, to_room: room_c, direction: "east")
    GridExit.create!(from_room: room_c, to_room: room_b, direction: "west")
  end

  def build
    described_class.new(zone: zone, hackr: hackr).build
  end

  it "returns a ZoneMapResult" do
    result = build
    expect(result).to be_a(described_class::ZoneMapResult)
  end

  it "includes all rooms in zone with BFS positions" do
    result = build
    expect(result.rooms.size).to eq(3)
    result.rooms.each do |r|
      expect(r[:map_x]).to be_a(Integer)
      expect(r[:map_y]).to be_a(Integer)
    end
  end

  it "marks current room" do
    result = build
    current = result.rooms.find { |r| r[:id] == room_a.id }
    expect(current[:is_current]).to be true
    other = result.rooms.find { |r| r[:id] == room_b.id }
    expect(other[:is_current]).to be false
  end

  describe "fog of war" do
    it "marks visited rooms" do
      Grid::RoomVisitRecorder.record!(hackr: hackr, room: room_a)
      result = build
      visited = result.rooms.find { |r| r[:id] == room_a.id }
      unvisited = result.rooms.find { |r| r[:id] == room_b.id }
      expect(visited[:visited]).to be true
      expect(unvisited[:visited]).to be false
    end

    it "always marks current room as visited" do
      # No visit record, but hackr is in room_a
      result = build
      current = result.rooms.find { |r| r[:id] == room_a.id }
      expect(current[:visited]).to be true
    end

    it "hides hackr presence on unvisited rooms" do
      other_hackr = create(:grid_hackr, current_room: room_b)
      result = build
      room_b_data = result.rooms.find { |r| r[:id] == room_b.id }
      expect(room_b_data[:hackr_aliases]).to be_empty
      expect(room_b_data[:hackr_count]).to eq(0)

      # Now visit it
      Grid::RoomVisitRecorder.record!(hackr: hackr, room: room_b)
      result2 = build
      room_b_data2 = result2.rooms.find { |r| r[:id] == room_b.id }
      expect(room_b_data2[:hackr_aliases]).to include(other_hackr.hackr_alias)
      expect(room_b_data2[:hackr_count]).to eq(1)
    end
  end

  describe "hackr presence" do
    it "includes hackr aliases for visited rooms" do
      Grid::RoomVisitRecorder.record!(hackr: hackr, room: room_a)
      result = build
      current = result.rooms.find { |r| r[:id] == room_a.id }
      expect(current[:hackr_aliases]).to include(hackr.hackr_alias)
    end
  end

  describe "exits" do
    it "returns intra-zone exits" do
      result = build
      expect(result.exits.size).to eq(4)
      directions = result.exits.map { |e| e[:direction] }
      expect(directions).to include("north", "south", "east", "west")
    end
  end

  describe "ghost rooms" do
    it "returns cross-zone exit targets as ghosts" do
      zone2 = create(:grid_zone, grid_region: region)
      room_d = create(:grid_room, grid_zone: zone2)
      GridExit.create!(from_room: room_c, to_room: room_d, direction: "east")

      result = build
      expect(result.ghost_rooms.size).to eq(1)
      ghost = result.ghost_rooms.first
      expect(ghost[:id]).to eq(room_d.id)
      expect(ghost[:zone_name]).to eq(zone2.name)
      expect(ghost[:local_room_id]).to eq(room_c.id)
      expect(ghost[:direction]).to eq("east")
    end
  end

  describe "z-levels" do
    it "computes z-levels from up/down exits" do
      room_up = create(:grid_room, grid_zone: zone)
      GridExit.create!(from_room: room_a, to_room: room_up, direction: "up")
      GridExit.create!(from_room: room_up, to_room: room_a, direction: "down")

      result = build
      up_data = result.rooms.find { |r| r[:id] == room_up.id }
      base_data = result.rooms.find { |r| r[:id] == room_a.id }
      expect(up_data[:map_z]).to eq(1)
      expect(base_data[:map_z]).to eq(0)
    end

    it "places up/down rooms at same x,y as parent" do
      room_up = create(:grid_room, grid_zone: zone)
      GridExit.create!(from_room: room_a, to_room: room_up, direction: "up")

      result = build
      up_data = result.rooms.find { |r| r[:id] == room_up.id }
      base_data = result.rooms.find { |r| r[:id] == room_a.id }
      expect(up_data[:map_x]).to eq(base_data[:map_x])
      expect(up_data[:map_y]).to eq(base_data[:map_y])
    end
  end

  describe "zone metadata" do
    it "includes zone and region info" do
      result = build
      expect(result.zone[:name]).to eq(zone.name)
      expect(result.zone[:region_name]).to eq(region.name)
    end
  end
end
