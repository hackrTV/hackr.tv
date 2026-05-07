# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::TransitCommandParser do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room_a) { create(:grid_room, grid_zone: zone, name: "Stop A") }
  let(:room_b) { create(:grid_room, grid_zone: zone, name: "Stop B") }
  let(:room_c) { create(:grid_room, grid_zone: zone, name: "Stop C") }
  let(:hackr) { create(:grid_hackr, current_room: room_a) }

  let(:transit_type) { create(:grid_transit_type, :public_type) }
  let!(:burn_cache) { create(:grid_cache, :burn) }
  let(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }

  let(:route) do
    create(:grid_transit_route, grid_transit_type: transit_type, grid_region: region).tap do |r|
      create(:grid_transit_stop, grid_transit_route: r, grid_room: room_a, position: 0, is_terminus: true)
      create(:grid_transit_stop, grid_transit_route: r, grid_room: room_b, position: 1)
      create(:grid_transit_stop, grid_transit_route: r, grid_room: room_c, position: 2, is_terminus: true)
    end
  end

  def fund_cache(target_cache, amount)
    source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: source, to_cache: target_cache, amount: amount,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  def execute(input)
    Grid::CommandParser.new(hackr, input).execute
  end

  before do
    fund_cache(cache, 1000)
    route # ensure created
  end

  # Helper: board the hackr onto the route so TransitCommandParser takes over
  def board_hackr!
    Grid::LocalTransitService.board!(hackr: hackr, route: route)
  end

  describe "local transit command routing" do
    before { board_hackr! }

    it "routes 'wait' to advance one stop" do
      result = execute("wait")
      expect(result[:output]).to include("Stop B")
      expect(hackr.reload.current_room).to eq(room_b)
    end

    it "routes 'w' alias to wait" do
      result = execute("w")
      expect(result[:output]).to include("Stop B")
    end

    it "routes 'ride' alias to wait" do
      result = execute("ride")
      expect(result[:output]).to include("Stop B")
    end

    it "routes 'disembark' to exit transit" do
      execute("wait") # move to B
      result = execute("disembark")
      expect(result[:output]).to include("disembark")
      expect(hackr.reload.active_journey).to be_nil
    end

    it "routes 'off' alias to disembark" do
      execute("wait")
      result = execute("off")
      expect(hackr.reload.active_journey).to be_nil
    end

    it "routes 'abandon' to abort transit" do
      execute("wait") # move to B
      result = execute("abandon")
      expect(result[:output]).to include("abandoned")
      expect(hackr.reload.current_room).to eq(room_a) # returned to origin
    end

    it "routes 'status' to show journey info" do
      result = execute("status")
      expect(result[:output]).to include("IN TRANSIT")
      expect(result[:output]).to include(route.name)
    end

    it "routes 'tr' alias to status" do
      result = execute("tr")
      expect(result[:output]).to include("IN TRANSIT")
    end
  end

  describe "blocked commands" do
    before { board_hackr! }

    %w[go north south breach buy sell fabricate equip].each do |cmd|
      it "blocks '#{cmd}' with informative message" do
        result = execute(cmd)
        expect(result[:output]).to include("In transit")
        expect(result[:output]).to include("unavailable")
      end
    end
  end

  describe "passthrough commands" do
    before { board_hackr! }

    it "passes 'look' through to main parser" do
      result = execute("look")
      expect(result[:output]).to include(room_a.name.upcase) # look renders room name
    end

    it "passes 'stat' through to main parser" do
      result = execute("stat")
      expect(result[:output]).not_to include("unavailable")
    end

    it "passes 'inventory' through to main parser" do
      result = execute("inv")
      expect(result[:output]).not_to include("unavailable")
    end
  end

  describe "slipstream command routing" do
    let(:dest_region) { create(:grid_region) }
    let(:dest_zone) { create(:grid_zone, grid_region: dest_region) }
    let(:origin_room) { create(:grid_room, grid_zone: zone) }
    let(:dest_room) { create(:grid_room, grid_zone: dest_zone) }

    let(:slip_route) do
      create(:grid_slipstream_route,
        origin_region: region, destination_region: dest_region,
        origin_room: origin_room, destination_room: dest_room,
        detection_risk_base: 0)
    end

    let!(:leg1) do
      create(:grid_slipstream_leg, grid_slipstream_route: slip_route, position: 1, name: "Leg 1")
    end
    let!(:leg2) do
      create(:grid_slipstream_leg, grid_slipstream_route: slip_route, position: 2, name: "Leg 2",
        fork_options: [])
    end

    let(:slip_hackr) { create(:grid_hackr, current_room: origin_room, stats: {"clearance" => 20}) }

    def slip_execute(input)
      Grid::CommandParser.new(slip_hackr, input).execute
    end

    before do
      Grid::SlipstreamService.board!(hackr: slip_hackr, route: slip_route)
    end

    it "routes 'choose' to fork selection" do
      result = slip_execute("choose A")
      expect(result[:output]).to include("Maintenance Corridor")
    end

    it "routes 'ch' alias to choose" do
      result = slip_execute("ch B")
      expect(result[:output]).to include("Freight Car")
    end

    it "routes 'advance' to traverse leg" do
      slip_execute("choose A")
      result = slip_execute("advance")
      expect(result[:output]).to include("Leg 2")
    end

    it "'wait' aliases to advance for slipstream" do
      slip_execute("choose A")
      result = slip_execute("wait")
      expect(result[:output]).to include("Leg 2")
    end

    it "'advance' without fork choice shows fork prompt" do
      result = slip_execute("advance")
      expect(result[:output]).to include("Choose your path")
    end

    it "blocks 'disembark' on slipstream" do
      result = slip_execute("disembark")
      expect(result[:output]).to include("Cannot disembark from Slipstream")
    end

    it "'choose' on local transit returns error" do
      board_hackr! # local transit journey for `hackr`
      result = execute("choose A")
      expect(result[:output]).to include("only available on Slipstream")
    end

    it "'advance' on local transit returns error" do
      board_hackr!
      result = execute("advance")
      expect(result[:output]).to include("Slipstream transit")
    end

    it "completes full slipstream journey" do
      slip_execute("choose A")
      slip_execute("advance") # leg 1 → leg 2 (no forks)
      result = slip_execute("advance") # leg 2 → arrival

      expect(result[:output]).to include("TRANSIT COMPLETE")
      expect(slip_hackr.reload.current_room).to eq(dest_room)
      expect(slip_hackr.active_journey).to be_nil
    end
  end

  describe "empty input" do
    before { board_hackr! }

    it "returns prompt message" do
      result = execute("")
      expect(result[:output]).to include("Please enter a command")
    end
  end
end
