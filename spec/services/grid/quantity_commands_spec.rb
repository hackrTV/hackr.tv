# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Command Quantity Syntax", type: :service do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:parser) { Grid::CommandParser.new(hackr, input) }
  let(:definition) { create(:grid_item_definition, item_type: "material", max_stack: 10, name: "Scrap Metal") }

  describe "take with quantity" do
    let!(:floor_item) { create(:grid_item, grid_item_definition: definition, room: room, quantity: 5) }

    context "take 3 scrap metal" do
      let(:input) { "take 3 scrap metal" }

      it "takes 3 from the floor stack" do
        result = parser.execute
        expect(result[:output]).to include("Scrap Metal")
        expect(result[:output]).to include("×3")
        floor_item.reload
        expect(floor_item.quantity).to eq(2)
        expect(hackr.grid_items.in_inventory(hackr).find_by(grid_item_definition: definition).quantity).to eq(3)
      end
    end

    context "take all scrap metal" do
      let(:input) { "take all scrap metal" }

      it "takes entire stack" do
        result = parser.execute
        expect(result[:output]).to include("Scrap Metal")
        expect(result[:output]).to include("×5")
        floor_item.reload
        expect(floor_item.grid_hackr).to eq(hackr)
        expect(floor_item.room).to be_nil
      end
    end

    context "take scrap metal (no quantity = 1)" do
      let(:input) { "take scrap metal" }

      it "takes exactly 1" do
        result = parser.execute
        expect(result[:output]).to include("Scrap Metal")
        expect(result[:output]).not_to include("×")
        floor_item.reload
        expect(floor_item.quantity).to eq(4)
      end
    end

    context "quantity exceeds available" do
      let(:input) { "take 10 scrap metal" }

      it "refuses with error" do
        result = parser.execute
        expect(result[:output]).to include("only have 5")
      end
    end
  end

  describe "drop with quantity" do
    let!(:inv_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 8) }

    context "drop 3 scrap metal" do
      let(:input) { "drop 3 scrap metal" }

      it "drops 3 from inventory to floor" do
        result = parser.execute
        expect(result[:output]).to include("Scrap Metal")
        expect(result[:output]).to include("×3")
        inv_item.reload
        expect(inv_item.quantity).to eq(5)
        floor_item = room.grid_items.on_floor(room).find_by(grid_item_definition: definition)
        expect(floor_item.quantity).to eq(3)
      end
    end

    context "drop all scrap metal" do
      let(:input) { "drop all scrap metal" }

      it "drops entire stack" do
        result = parser.execute
        expect(result[:output]).to include("×8")
        inv_item.reload
        expect(inv_item.room).to eq(room)
        expect(inv_item.grid_hackr).to be_nil
      end
    end

    context "drop scrap metal (no quantity = 1)" do
      let(:input) { "drop scrap metal" }

      it "drops exactly 1" do
        result = parser.execute
        expect(result[:output]).to include("Scrap Metal")
        expect(result[:output]).not_to include("×")
        inv_item.reload
        expect(inv_item.quantity).to eq(7)
      end
    end
  end

  describe "give with quantity" do
    let!(:inv_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 5, name: "Basic CPU") }
    let!(:mob) { create(:grid_mob, grid_room: room, name: "Nighthawk", mob_type: "quest_giver") }

    let(:mission) { create(:grid_mission, giver_mob: mob, published: true) }
    let!(:hackr_mission) { create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission, status: "active") }
    let(:objective) do
      create(:grid_mission_objective,
        grid_mission: mission,
        objective_type: "deliver_item",
        target_slug: "basic cpu",
        target_count: 5)
    end
    let!(:hackr_objective) do
      create(:grid_hackr_mission_objective,
        grid_hackr_mission: hackr_mission,
        grid_mission_objective: objective,
        progress: 0)
    end

    context "give 5 basic cpu to nighthawk" do
      let(:input) { "give 5 basic cpu to nighthawk" }

      it "gives 5 at once and advances mission by 5" do
        result = parser.execute
        expect(result[:output]).to include("×5")
        expect(result[:output]).to include("Nighthawk")
        expect(GridItem.find_by(id: inv_item.id)).to be_nil
        hackr_objective.reload
        expect(hackr_objective.progress).to eq(5)
        expect(hackr_objective.completed_at).to be_present
      end
    end

    context "give basic cpu to nighthawk (no quantity = 1)" do
      # Override objective to target_count: 1 so a single delivery completes it.
      # The give command only consumes items when the progressor returns a
      # completion notification (by design — prevents consuming items when
      # no objective matches).
      let(:objective) do
        create(:grid_mission_objective,
          grid_mission: mission,
          objective_type: "deliver_item",
          target_slug: "basic cpu",
          target_count: 1)
      end
      let(:input) { "give basic cpu to nighthawk" }

      it "gives 1 and completes the objective" do
        result = parser.execute
        expect(result[:output]).not_to include("×")
        inv_item.reload
        expect(inv_item.quantity).to eq(4)
        hackr_objective.reload
        expect(hackr_objective.progress).to eq(1)
        expect(hackr_objective.completed_at).to be_present
      end
    end

    context "no matching mission objective" do
      let(:input) { "give 3 scrap metal to nighthawk" }
      let!(:scrap_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, name: "Scrap Metal", quantity: 5) }

      it "rolls back and NPC declines" do
        result = parser.execute
        expect(result[:output]).to include("no use for that")
        scrap_item.reload
        expect(scrap_item.quantity).to eq(5)
      end
    end
  end

  describe "store with quantity" do
    let(:den_zone) { create(:grid_zone, slug: "residential-district-#{SecureRandom.hex(4)}") }
    let(:den) { create(:grid_room, :den, grid_zone: den_zone, owner: hackr) }
    let(:fixture_def) { create(:grid_item_definition, :fixture) }
    let!(:fixture) { create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def) }
    let!(:inv_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 6) }

    before { hackr.update!(current_room: den) }

    context "store 3 scrap metal in fixture" do
      let(:input) { "store 3 #{definition.name} in #{fixture.name}" }

      it "stores 3 in fixture, keeps 3 in inventory" do
        result = parser.execute
        expect(result[:output]).to include("Stored")
        expect(result[:output]).to include("×3")
        inv_item.reload
        expect(inv_item.quantity).to eq(3)
        stored = fixture.stored_items.find_by(grid_item_definition: definition)
        expect(stored.quantity).to eq(3)
      end
    end

    context "store all scrap metal in fixture" do
      let(:input) { "store all #{definition.name} in #{fixture.name}" }

      it "stores entire stack" do
        result = parser.execute
        expect(result[:output]).to include("×6")
        inv_item.reload
        expect(inv_item.container).to eq(fixture)
      end
    end
  end

  describe "retrieve with quantity" do
    let(:den_zone) { create(:grid_zone, slug: "residential-district-#{SecureRandom.hex(4)}") }
    let(:den) { create(:grid_room, :den, grid_zone: den_zone, owner: hackr) }
    let(:fixture_def) { create(:grid_item_definition, :fixture) }
    let!(:fixture) { create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def) }
    let!(:stored_item) do
      create(:grid_item, grid_item_definition: definition, container: fixture,
        room: nil, grid_hackr: nil, quantity: 7)
    end

    before { hackr.update!(current_room: den) }

    context "retrieve 4 scrap metal from fixture" do
      let(:input) { "retrieve 4 #{definition.name} from #{fixture.name}" }

      it "retrieves 4, leaves 3 in fixture" do
        result = parser.execute
        expect(result[:output]).to include("Retrieved")
        expect(result[:output]).to include("×4")
        stored_item.reload
        expect(stored_item.quantity).to eq(3)
        inv = hackr.grid_items.in_inventory(hackr).find_by(grid_item_definition: definition)
        expect(inv.quantity).to eq(4)
      end
    end

    context "retrieve all from fixture" do
      let(:input) { "retrieve all #{definition.name} from #{fixture.name}" }

      it "retrieves entire stack" do
        result = parser.execute
        expect(result[:output]).to include("×7")
        stored_item.reload
        expect(stored_item.grid_hackr).to eq(hackr)
        expect(stored_item.container).to be_nil
      end
    end
  end

  describe "salvage with quantity" do
    let!(:inv_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 5) }

    context "salvage 3 scrap metal" do
      let(:input) { "salvage 3 scrap metal" }

      it "salvages 3 at once" do
        result = parser.execute
        expect(result[:output]).to include("×3")
        inv_item.reload
        expect(inv_item.quantity).to eq(2)
      end
    end

    context "salvage all scrap metal" do
      let(:input) { "salvage all scrap metal" }

      it "salvages entire stack" do
        result = parser.execute
        expect(result[:output]).to include("×5")
        expect(GridItem.find_by(id: inv_item.id)).to be_nil
      end
    end

    context "salvage scrap metal (no quantity = 1)" do
      let(:input) { "salvage scrap metal" }

      it "salvages exactly 1" do
        result = parser.execute
        expect(result[:output]).not_to include("×")
        inv_item.reload
        expect(inv_item.quantity).to eq(4)
      end
    end

    context "salvage 3 with yields (2 per unit)" do
      let(:yield_def) { create(:grid_item_definition, item_type: "material", name: "Raw Scrap", max_stack: 32) }
      let!(:salvage_yield) do
        create(:grid_salvage_yield,
          source_definition: definition,
          output_definition: yield_def,
          quantity: 2)
      end
      let(:input) { "salvage 3 scrap metal" }

      it "produces 6 yield items (2 per unit × 3)" do
        result = parser.execute
        expect(result[:output]).to include("×3")
        expect(result[:output]).to include("Raw Scrap")
        expect(result[:output]).to include("×6")
        yielded = hackr.grid_items.in_inventory(hackr).find_by(grid_item_definition: yield_def)
        expect(yielded.quantity).to eq(6)
      end
    end

    context "salvage item stored in fixture" do
      let(:fixture_def) { create(:grid_item_definition, :fixture) }
      let(:stored_def) { create(:grid_item_definition, item_type: "material", name: "Vault Chip") }
      let(:den) { create(:grid_room, :den, grid_zone: zone, owner: hackr) }
      let!(:fixture) { create(:grid_item, :placed_fixture, room: den, grid_item_definition: fixture_def) }
      let!(:stored_item) do
        create(:grid_item, grid_item_definition: stored_def, container: fixture,
          room: nil, grid_hackr: nil, quantity: 3)
      end
      let(:input) { "salvage vault chip" }

      before { hackr.update!(current_room: den) }

      it "cannot salvage items inside fixtures" do
        result = parser.execute
        expect(result[:output]).to include("don't have")
        expect(stored_item.reload.quantity).to eq(3)
      end
    end
  end

  describe "buy with quantity" do
    let!(:vendor) { create(:grid_mob, grid_room: room, mob_type: "vendor") }
    let(:buy_def) { create(:grid_item_definition, name: "Cipher Chip", item_type: "data", max_stack: 8) }
    let!(:listing) do
      create(:grid_shop_listing,
        grid_mob: vendor,
        grid_item_definition: buy_def,
        base_price: 10,
        active: true,
        stock: nil, max_stock: nil)
    end
    let(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }
    let(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }
    let(:burn_cache) { create(:grid_cache, :burn) }

    def fund_cache(target_cache, amount)
      source = create(:grid_cache)
      GridTransaction.create!(
        from_cache: source, to_cache: target_cache, amount: amount,
        tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
      )
    end

    before do
      cache
      gameplay_pool
      burn_cache
      fund_cache(cache, 500)
    end

    context "buy 3 cipher chip" do
      let(:input) { "buy 3 cipher chip" }

      it "buys 3 at once for 30 CRED" do
        result = parser.execute
        expect(result[:output]).to include("Purchased")
        expect(result[:output]).to include("×3")
        expect(result[:output]).to include("30")
        inv = hackr.grid_items.in_inventory(hackr).find_by(grid_item_definition: buy_def)
        expect(inv.quantity).to eq(3)
      end
    end

    context "buy all cipher chip" do
      let(:input) { "buy all cipher chip" }

      it "rejects 'all' for buy" do
        result = parser.execute
        expect(result[:output]).to include("Specify a number")
      end
    end

    context "buy 3 with limited stock of 2" do
      let!(:limited_listing) do
        create(:grid_shop_listing,
          grid_mob: vendor,
          grid_item_definition: buy_def,
          base_price: 10,
          active: true,
          stock: 2, max_stock: 5)
      end
      let(:input) { "buy 3 cipher chip" }

      before { listing.update!(active: false) } # disable unlimited listing

      it "refuses when stock insufficient" do
        result = parser.execute
        expect(result[:output]).to include("in stock")
        expect(hackr.grid_items.in_inventory(hackr).count).to eq(0)
      end
    end
  end

  describe "sell with quantity" do
    let!(:vendor) { create(:grid_mob, grid_room: room, mob_type: "vendor") }
    let!(:inv_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 5) }
    let(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }
    let(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }

    def fund_cache(target_cache, amount)
      source = create(:grid_cache)
      GridTransaction.create!(
        from_cache: source, to_cache: target_cache, amount: amount,
        tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
      )
    end

    before do
      cache
      gameplay_pool
      fund_cache(gameplay_pool, 100_000)
    end

    context "sell 3 scrap metal" do
      let(:input) { "sell 3 scrap metal" }

      it "sells 3 at once" do
        result = parser.execute
        expect(result[:output]).to include("Sold")
        expect(result[:output]).to include("×3")
        inv_item.reload
        expect(inv_item.quantity).to eq(2)
      end
    end

    context "sell all scrap metal" do
      let(:input) { "sell all scrap metal" }

      it "sells entire stack" do
        result = parser.execute
        expect(result[:output]).to include("×5")
        expect(GridItem.find_by(id: inv_item.id)).to be_nil
      end
    end
  end
end
