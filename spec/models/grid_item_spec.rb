# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id                      :integer          not null, primary key
#  description             :text
#  item_type               :string
#  name                    :string
#  properties              :json
#  quantity                :integer          default(1), not null
#  rarity                  :string
#  value                   :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  container_id            :integer
#  grid_hackr_id           :integer
#  grid_item_definition_id :integer          not null
#  grid_mining_rig_id      :integer
#  room_id                 :integer
#
# Indexes
#
#  index_grid_items_on_container_id             (container_id)
#  index_grid_items_on_grid_hackr_id            (grid_hackr_id)
#  index_grid_items_on_grid_item_definition_id  (grid_item_definition_id)
#  index_grid_items_on_grid_mining_rig_id       (grid_mining_rig_id)
#
# Foreign Keys
#
#  container_id             (container_id => grid_items.id)
#  grid_item_definition_id  (grid_item_definition_id => grid_item_definitions.id)
#
require "rails_helper"

RSpec.describe GridItem, type: :model do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr) }
  let(:fixture_def) { create(:grid_item_definition, :fixture) }
  let(:tool_def) { create(:grid_item_definition, item_type: "tool") }

  describe "#fixture?" do
    it "returns true for fixture items" do
      item = build(:grid_item, :fixture)
      expect(item.fixture?).to be true
    end

    it "returns false for non-fixture items" do
      item = build(:grid_item)
      expect(item.fixture?).to be false
    end
  end

  describe "#placed?" do
    it "returns true for a fixture with room_id set" do
      item = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      expect(item.placed?).to be true
    end

    it "returns false for a fixture in inventory" do
      item = create(:grid_item, :fixture, :in_inventory, grid_hackr: hackr, grid_item_definition: fixture_def)
      expect(item.placed?).to be false
    end

    it "returns false for non-fixture items in a room" do
      item = create(:grid_item, room: room)
      expect(item.placed?).to be false
    end
  end

  describe "#storage_capacity" do
    it "reads from properties" do
      item = build(:grid_item, :fixture, properties: {"storage_capacity" => 16})
      expect(item.storage_capacity).to eq(16)
    end

    it "returns 0 when not set" do
      item = build(:grid_item, properties: {})
      expect(item.storage_capacity).to eq(0)
    end
  end

  describe "single_location validation" do
    it "allows exactly one location FK set" do
      item = build(:grid_item, room: room, grid_hackr: nil, grid_mining_rig: nil, container: nil)
      expect(item).to be_valid
    end

    it "allows container_id as sole location" do
      fixture = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      item = build(:grid_item, container: fixture, room: nil, grid_hackr: nil, grid_mining_rig: nil)
      expect(item).to be_valid
    end

    it "rejects container_id + room_id" do
      fixture = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      item = build(:grid_item, container: fixture, room: room, grid_hackr: nil)
      expect(item).not_to be_valid
      expect(item.errors[:base].first).to include("one location")
    end

    it "rejects container_id + grid_hackr_id" do
      fixture = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      item = build(:grid_item, container: fixture, grid_hackr: hackr, room: nil)
      expect(item).not_to be_valid
    end

    it "allows zero locations (transitional state)" do
      item = build(:grid_item, room: nil, grid_hackr: nil, grid_mining_rig: nil, container: nil)
      expect(item).to be_valid
    end
  end

  describe "scopes" do
    let(:fixture) { create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def) }
    let(:floor_item) { create(:grid_item, room: room, grid_hackr: nil, grid_item_definition: tool_def) }
    let(:stored_item) { create(:grid_item, container: fixture, room: nil, grid_hackr: nil, grid_item_definition: tool_def) }
    let(:inv_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: tool_def) }

    before do
      fixture
      floor_item
      stored_item
      inv_item
    end

    describe ".in_room" do
      it "includes floor items and placed fixtures" do
        results = described_class.in_room(room)
        expect(results).to include(floor_item, fixture)
      end

      it "excludes container-stored items" do
        results = described_class.in_room(room)
        expect(results).not_to include(stored_item)
      end

      it "excludes inventory items" do
        results = described_class.in_room(room)
        expect(results).not_to include(inv_item)
      end
    end

    describe ".on_floor" do
      it "includes non-fixture floor items" do
        results = described_class.on_floor(room)
        expect(results).to include(floor_item)
      end

      it "excludes placed fixtures" do
        results = described_class.on_floor(room)
        expect(results).not_to include(fixture)
      end

      it "excludes container-stored items" do
        results = described_class.on_floor(room)
        expect(results).not_to include(stored_item)
      end
    end

    describe ".placed_fixtures" do
      it "includes placed fixtures" do
        results = described_class.placed_fixtures(room)
        expect(results).to include(fixture)
      end

      it "excludes non-fixture items" do
        results = described_class.placed_fixtures(room)
        expect(results).not_to include(floor_item)
      end
    end

    describe ".in_inventory" do
      it "excludes container-stored items" do
        results = described_class.in_inventory(hackr)
        expect(results).to include(inv_item)
        expect(results).not_to include(stored_item)
      end
    end
  end

  describe "stored_items association" do
    it "prevents deleting a fixture with stored items" do
      fixture = create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def)
      create(:grid_item, container: fixture, room: nil, grid_hackr: nil, grid_item_definition: tool_def)

      expect(fixture.destroy).to be false
      expect(fixture.errors[:base].first).to include("Cannot delete")
    end
  end
end
