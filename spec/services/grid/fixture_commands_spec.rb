# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Fixture Commands", type: :service do
  let(:zone) { create(:grid_zone, slug: "residential-district") }
  let(:corridor) { create(:grid_room, :hub, grid_zone: zone, slug: "residential-corridor", name: "Residential Corridor") }
  let(:hackr) { create(:grid_hackr, current_room: den) }
  let(:den) { Grid::DenService.new(hackr_for_den).create_den! }
  let(:hackr_for_den) { create(:grid_hackr) }
  let(:parser) { Grid::CommandParser.new(hackr, input) }

  before do
    corridor # ensure corridor exists
    # hackr_for_den creates the den, then we set hackr to own it
    den
    hackr_for_den.update!(current_room: den)
  end

  # Use hackr_for_den as the actual hackr in all tests
  let(:hackr) { hackr_for_den }

  let(:fixture_def) { create(:grid_item_definition, :fixture) }
  let(:fixture_item) do
    create(:grid_item, :fixture, :in_inventory, grid_hackr: hackr, grid_item_definition: fixture_def)
  end

  describe "place command" do
    before { fixture_item }

    context "happy path" do
      let(:input) { "place #{fixture_item.name}" }

      it "moves fixture from inventory to den" do
        result = parser.execute
        expect(result[:output]).to include("Installed")
        fixture_item.reload
        expect(fixture_item.room).to eq(den)
        expect(fixture_item.grid_hackr).to be_nil
      end

      it "counts as a placed fixture for achievements" do
        parser.execute
        expect(den.placed_fixtures.distinct.count(:grid_item_definition_id)).to eq(1)
      end
    end

    context "not in own den" do
      let(:other_room) { create(:grid_room, grid_zone: zone) }
      let(:input) { "place #{fixture_item.name}" }

      before { hackr.update!(current_room: other_room) }

      it "rejects with error" do
        result = parser.execute
        expect(result[:output]).to include("only place fixtures in your own den")
      end
    end

    context "item is not a fixture" do
      let(:tool_item) { create(:grid_item, :in_inventory, grid_hackr: hackr) }
      let(:input) { "place #{tool_item.name}" }

      before { tool_item }

      it "rejects non-fixture items" do
        result = parser.execute
        expect(result[:output]).to include("not a fixture")
      end
    end

    context "fixture limit reached" do
      let(:input) { "place #{fixture_item.name}" }

      before do
        Grid::DenService::MAX_DEN_FIXTURES.times do
          d = create(:grid_item_definition, :fixture)
          create(:grid_item, :placed_fixture, room: den, grid_item_definition: d)
        end
      end

      it "rejects when at max fixtures" do
        result = parser.execute
        expect(result[:output]).to include("Fixture limit reached")
      end
    end

    context "aliases" do
      let(:input) { "install #{fixture_item.name}" }

      it "works with install alias" do
        result = parser.execute
        expect(result[:output]).to include("Installed")
      end
    end
  end

  describe "unplace command" do
    let(:placed_fixture) do
      create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
    end

    before { placed_fixture }

    context "happy path" do
      let(:input) { "unplace #{placed_fixture.name}" }

      it "moves fixture back to inventory" do
        result = parser.execute
        expect(result[:output]).to include("uninstalled")
        placed_fixture.reload
        expect(placed_fixture.grid_hackr).to eq(hackr)
        expect(placed_fixture.room).to be_nil
      end
    end

    context "fixture has stored items" do
      let(:input) { "unplace #{placed_fixture.name}" }
      let(:stored_item) do
        create(:grid_item, container: placed_fixture, grid_item_definition: create(:grid_item_definition),
          room: nil, grid_hackr: nil)
      end

      before { stored_item }

      it "rejects when fixture contains items" do
        result = parser.execute
        expect(result[:output]).to include("Retrieve them first")
      end
    end

    context "inventory full" do
      let(:input) { "unplace #{placed_fixture.name}" }

      before do
        hackr.stat("clearance") # ensure stats initialized
        16.times do
          create(:grid_item, :in_inventory, grid_hackr: hackr)
        end
      end

      it "rejects when inventory is full" do
        result = parser.execute
        expect(result[:output]).to include("Inventory full")
      end
    end

    context "not in own den" do
      let(:other_room) { create(:grid_room, grid_zone: zone) }
      let(:input) { "unplace #{placed_fixture.name}" }

      before { hackr.update!(current_room: other_room) }

      it "rejects with error" do
        result = parser.execute
        expect(result[:output]).to include("only unplace fixtures from your own den")
      end
    end

    context "fixture not found" do
      let(:input) { "unplace nonexistent" }

      it "returns not found error" do
        result = parser.execute
        expect(result[:output]).to include("No placed fixture called")
      end
    end

    context "uninstall alias" do
      let(:input) { "uninstall #{placed_fixture.name}" }

      it "works with uninstall alias" do
        result = parser.execute
        expect(result[:output]).to include("uninstalled")
      end
    end
  end

  describe "store command" do
    let(:placed_fixture) do
      create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
    end
    let(:item_to_store) { create(:grid_item, :in_inventory, grid_hackr: hackr) }

    before do
      placed_fixture
      item_to_store
    end

    context "happy path" do
      let(:input) { "store #{item_to_store.name} in #{placed_fixture.name}" }

      it "moves item from inventory to fixture" do
        result = parser.execute
        expect(result[:output]).to include("Stored")
        item_to_store.reload
        expect(item_to_store.container).to eq(placed_fixture)
        expect(item_to_store.grid_hackr).to be_nil
        expect(item_to_store.room).to be_nil
      end
    end

    context "fixture is full" do
      let(:input) { "store #{item_to_store.name} in #{placed_fixture.name}" }

      before do
        placed_fixture.storage_capacity.times do
          create(:grid_item, container: placed_fixture, grid_item_definition: create(:grid_item_definition),
            room: nil, grid_hackr: nil)
        end
      end

      it "rejects when fixture is full" do
        result = parser.execute
        expect(result[:output]).to include("full")
      end
    end

    context "storing a fixture inside another fixture" do
      let(:second_fixture) { create(:grid_item, :fixture, :in_inventory, grid_hackr: hackr) }
      let(:input) { "store #{second_fixture.name} in #{placed_fixture.name}" }

      before { second_fixture }

      it "rejects nesting" do
        result = parser.execute
        expect(result[:output]).to include("can't store a fixture inside another fixture")
      end
    end

    context "visitor cannot store" do
      let(:visitor) { create(:grid_hackr, current_room: den) }
      let(:visitor_item) { create(:grid_item, :in_inventory, grid_hackr: visitor) }
      let(:parser) { Grid::CommandParser.new(visitor, input) }
      let(:input) { "store #{visitor_item.name} in #{placed_fixture.name}" }

      before { visitor_item }

      it "rejects visitors from storing" do
        result = parser.execute
        expect(result[:output]).to include("only store items in fixtures in your own den")
      end
    end

    context "put alias" do
      let(:input) { "put #{item_to_store.name} in #{placed_fixture.name}" }

      it "works with put alias" do
        result = parser.execute
        expect(result[:output]).to include("Stored")
      end
    end
  end

  describe "retrieve command" do
    let(:placed_fixture) do
      create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
    end
    let(:stored_item) do
      create(:grid_item, container: placed_fixture, grid_item_definition: create(:grid_item_definition),
        room: nil, grid_hackr: nil)
    end

    before do
      placed_fixture
      stored_item
    end

    context "happy path" do
      let(:input) { "retrieve #{stored_item.name} from #{placed_fixture.name}" }

      it "moves item from fixture to inventory" do
        result = parser.execute
        expect(result[:output]).to include("Retrieved")
        stored_item.reload
        expect(stored_item.grid_hackr).to eq(hackr)
        expect(stored_item.container).to be_nil
      end
    end

    context "item not in fixture" do
      let(:input) { "retrieve nonexistent from #{placed_fixture.name}" }

      it "returns error when item not found" do
        result = parser.execute
        expect(result[:output]).to include("doesn't contain")
      end
    end

    context "inventory full" do
      let(:input) { "retrieve #{stored_item.name} from #{placed_fixture.name}" }

      before do
        16.times do
          create(:grid_item, :in_inventory, grid_hackr: hackr)
        end
      end

      it "rejects when inventory is full" do
        result = parser.execute
        expect(result[:output]).to include("Inventory full")
      end
    end

    context "visitor cannot retrieve" do
      let(:visitor) { create(:grid_hackr, current_room: den) }
      let(:parser) { Grid::CommandParser.new(visitor, input) }
      let(:input) { "retrieve #{stored_item.name} from #{placed_fixture.name}" }

      it "rejects visitors" do
        result = parser.execute
        expect(result[:output]).to include("only retrieve items from fixtures in your own den")
      end
    end
  end

  describe "peek command" do
    let(:placed_fixture) do
      create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
    end

    before { placed_fixture }

    context "empty fixture" do
      let(:input) { "peek #{placed_fixture.name}" }

      it "shows empty fixture" do
        result = parser.execute
        expect(result[:output]).to include(placed_fixture.name)
        expect(result[:output]).to include("0/#{placed_fixture.storage_capacity}")
        expect(result[:output]).to include("Empty")
      end
    end

    context "fixture with items" do
      let(:stored_item) do
        create(:grid_item, container: placed_fixture, grid_item_definition: create(:grid_item_definition, name: "Data Shard"),
          room: nil, grid_hackr: nil, name: "Data Shard")
      end
      let(:input) { "peek #{placed_fixture.name}" }

      before { stored_item }

      it "lists stored items" do
        result = parser.execute
        expect(result[:output]).to include("Data Shard")
        expect(result[:output]).to include("1/#{placed_fixture.storage_capacity}")
      end
    end

    context "visitor can peek" do
      let(:visitor) { create(:grid_hackr, current_room: den) }
      let(:parser) { Grid::CommandParser.new(visitor, input) }
      let(:input) { "peek #{placed_fixture.name}" }

      it "allows visitors to peek" do
        result = parser.execute
        expect(result[:output]).to include(placed_fixture.name)
        expect(result[:output]).not_to include("can't")
      end
    end

    context "search alias" do
      let(:input) { "search #{placed_fixture.name}" }

      it "works with search alias" do
        result = parser.execute
        expect(result[:output]).to include(placed_fixture.name)
      end
    end
  end

  describe "take command with placed fixture" do
    let(:placed_fixture) do
      create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
    end

    before { placed_fixture }

    context "empty fixture can be taken" do
      let(:input) { "take #{placed_fixture.name}" }

      it "allows taking empty placed fixture" do
        result = parser.execute
        expect(result[:output]).to include("You take")
        placed_fixture.reload
        expect(placed_fixture.grid_hackr).to eq(hackr)
        expect(placed_fixture.room).to be_nil
      end
    end

    context "non-empty fixture cannot be taken" do
      let(:stored_item) do
        create(:grid_item, container: placed_fixture, grid_item_definition: create(:grid_item_definition),
          room: nil, grid_hackr: nil)
      end
      let(:input) { "take #{placed_fixture.name}" }

      before { stored_item }

      it "blocks take on non-empty fixture" do
        result = parser.execute
        expect(result[:output]).to include("Retrieve them first")
      end
    end
  end

  describe "salvage command with placed fixture" do
    let(:placed_fixture) do
      create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
    end

    before { placed_fixture }

    # salvage searches hackr.grid_items — placed fixtures have grid_hackr: nil,
    # so they won't be found. But an in-inventory fixture should be salvageable.
    context "fixture in inventory" do
      let(:inv_fixture) { create(:grid_item, :fixture, :in_inventory, grid_hackr: hackr, grid_item_definition: fixture_def) }
      let(:input) { "salvage #{inv_fixture.name}" }

      before { inv_fixture }

      it "allows salvaging unplaced fixture" do
        result = parser.execute
        # Won't error about being placed — will proceed to salvage logic
        expect(result[:output]).not_to include("Unplace")
      end
    end
  end

  describe "drop command with fixture" do
    let(:input) { "drop #{fixture_item.name}" }

    before { fixture_item }

    it "blocks dropping fixtures with a hint to use place" do
      result = parser.execute
      expect(result[:output]).to include("place")
    end
  end

  describe "examine command on fixture" do
    context "placed fixture" do
      let(:placed_fixture) do
        create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
      end
      let(:input) { "examine #{placed_fixture.name}" }

      before { placed_fixture }

      it "shows storage capacity and placed status" do
        result = parser.execute
        expect(result[:output]).to include("Storage Fixture")
        expect(result[:output]).to include("PLACED")
        expect(result[:output]).to include("#{placed_fixture.storage_capacity} slots")
      end

      it "shows peek hint" do
        result = parser.execute
        expect(result[:output]).to include("peek")
      end
    end

    context "fixture in inventory" do
      let(:input) { "examine #{fixture_item.name}" }

      before { fixture_item }

      it "shows capacity and place hint" do
        result = parser.execute
        expect(result[:output]).to include("Storage Fixture")
        expect(result[:output]).to include("in inventory")
        expect(result[:output]).to include("place")
      end
    end
  end

  describe "look command with fixtures" do
    let(:placed_fixture) do
      create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
    end
    let(:floor_item) do
      create(:grid_item, room: den, grid_hackr: nil, grid_item_definition: create(:grid_item_definition, name: "Scrap Metal"), name: "Scrap Metal")
    end

    before do
      placed_fixture
      floor_item
    end

    let(:input) { "look" }

    it "shows fixtures in a separate section" do
      result = parser.execute
      expect(result[:output]).to include("Fixtures:")
      expect(result[:output]).to include(placed_fixture.name)
    end

    it "shows floor items separately from fixtures" do
      result = parser.execute
      expect(result[:output]).to include("Items:")
      expect(result[:output]).to include("Scrap Metal")
    end

    it "shows floor count in den banner" do
      result = parser.execute
      expect(result[:output]).to include("Floor:")
    end
  end

  describe "den status with fixtures" do
    let(:placed_fixture) do
      create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def)
    end

    before { placed_fixture }

    let(:input) { "den" }

    it "shows fixture info in den status" do
      result = parser.execute
      expect(result[:output]).to include("Fixtures")
      expect(result[:output]).to include(placed_fixture.name)
    end
  end
end
