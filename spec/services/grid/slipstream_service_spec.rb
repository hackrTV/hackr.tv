# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::SlipstreamService do
  let(:origin_region) { create(:grid_region) }
  let(:dest_region) { create(:grid_region) }
  let(:origin_zone) { create(:grid_zone, grid_region: origin_region) }
  let(:dest_zone) { create(:grid_zone, grid_region: dest_region) }
  let(:origin_room) { create(:grid_room, grid_zone: origin_zone) }
  let(:dest_room) { create(:grid_room, grid_zone: dest_zone) }
  let(:hackr) { create(:grid_hackr, current_room: origin_room, stats: {"clearance" => 20}) }

  let(:route) do
    create(:grid_slipstream_route,
      origin_region: origin_region,
      destination_region: dest_region,
      origin_room: origin_room,
      destination_room: dest_room,
      detection_risk_base: 0) # Disable detection for predictable tests
  end

  let!(:leg1) do
    create(:grid_slipstream_leg, grid_slipstream_route: route, position: 1, name: "Leg 1")
  end
  let!(:leg2) do
    create(:grid_slipstream_leg, grid_slipstream_route: route, position: 2, name: "Leg 2",
      fork_options: [])
  end

  describe ".board!" do
    it "creates an active slipstream journey" do
      result = described_class.board!(hackr: hackr, route: route)

      expect(result.journey.state).to eq("active")
      expect(result.journey.journey_type).to eq("slipstream")
      expect(result.journey.current_leg).to eq(leg1)
      expect(result.journey.pending_fork).to be true
      expect(result.display).to include("SLIPSTREAM INITIATED")
    end

    it "raises ClearanceRequired when hackr clearance is too low" do
      hackr.set_stat!("clearance", 5)
      expect {
        described_class.board!(hackr: hackr, route: route)
      }.to raise_error(Grid::SlipstreamService::ClearanceRequired)
    end

    it "raises NotAtBoardingPoint when hackr is not at origin room" do
      hackr.update!(current_room: dest_room)
      expect {
        described_class.board!(hackr: hackr, route: route)
      }.to raise_error(Grid::SlipstreamService::NotAtBoardingPoint)
    end

    it "raises AlreadyInJourney when hackr has active journey" do
      described_class.board!(hackr: hackr, route: route)
      expect {
        described_class.board!(hackr: hackr, route: route)
      }.to raise_error(Grid::SlipstreamService::AlreadyInJourney)
    end
  end

  describe ".choose_fork!" do
    before { described_class.board!(hackr: hackr, route: route) }

    it "records fork choice and clears pending_fork" do
      result = described_class.choose_fork!(hackr: hackr, fork_key: "A")

      expect(result.journey.pending_fork).to be false
      expect(result.journey.chosen_forks).to eq({"1" => "A"})
      expect(result.display).to include("Maintenance Corridor")
    end

    it "raises InvalidForkKey for unknown fork" do
      expect {
        described_class.choose_fork!(hackr: hackr, fork_key: "Z")
      }.to raise_error(Grid::SlipstreamService::InvalidForkKey)
    end

    it "raises NotAwaitingFork when no fork pending" do
      described_class.choose_fork!(hackr: hackr, fork_key: "A")
      expect {
        described_class.choose_fork!(hackr: hackr, fork_key: "B")
      }.to raise_error(Grid::SlipstreamService::NotAwaitingFork)
    end
  end

  describe ".advance_leg!" do
    before do
      described_class.board!(hackr: hackr, route: route)
      described_class.choose_fork!(hackr: hackr, fork_key: "A")
    end

    it "advances to next leg" do
      result = described_class.advance_leg!(hackr: hackr)

      expect(result.completed).to be false
      expect(result.breach_triggered).to be false
      expect(result.journey.current_leg).to eq(leg2)
      expect(result.journey.legs_completed).to eq(1)
    end

    it "completes journey on final leg" do
      described_class.advance_leg!(hackr: hackr) # Leg 1 → Leg 2 (no forks)
      result = described_class.advance_leg!(hackr: hackr) # Leg 2 → arrival

      expect(result.completed).to be true
      expect(result.journey.state).to eq("completed")
      expect(hackr.reload.current_room).to eq(dest_room)
      expect(result.display).to include("TRANSIT COMPLETE")
    end

    it "raises AwaitingFork when fork not yet chosen" do
      # Start fresh journey
      hackr2 = create(:grid_hackr, current_room: origin_room, stats: {"clearance" => 20})
      described_class.board!(hackr: hackr2, route: route)
      expect {
        described_class.advance_leg!(hackr: hackr2)
      }.to raise_error(Grid::SlipstreamService::AwaitingFork)
    end

    it "accumulates heat on successful leg traversal" do
      described_class.advance_leg!(hackr: hackr)
      journey = hackr.active_journey
      expect(journey.heat_accumulated).to be > 0
    end
  end

  describe ".abandon!" do
    before { described_class.board!(hackr: hackr, route: route) }

    it "sets journey to abandoned and returns hackr to origin" do
      result = described_class.abandon!(hackr: hackr)

      expect(result.journey.state).to eq("abandoned")
      expect(hackr.reload.current_room).to eq(origin_room)
    end
  end

  describe "slipstream stats" do
    before do
      described_class.board!(hackr: hackr, route: route)
      described_class.choose_fork!(hackr: hackr, fork_key: "A")
      described_class.advance_leg!(hackr: hackr) # Leg 1 → Leg 2
      described_class.advance_leg!(hackr: hackr) # Leg 2 → arrival
    end

    it "increments slipstream_trips_count" do
      expect(hackr.stat("slipstream_trips_count")).to eq(1)
    end

    it "tracks visited region IDs" do
      visited = hackr.stat("visited_region_ids")
      expect(visited).to include(dest_region.id)
    end

    it "applies heat to hackr on arrival" do
      expect(hackr.slipstream_heat).to be > 0
    end
  end

  describe "heat decay" do
    it "decays 1 point per minute" do
      hackr.set_stat!("slipstream_heat", 50)
      hackr.set_stat!("slipstream_heat_last_at", 10.minutes.ago.to_i)

      expect(hackr.slipstream_heat).to eq(40)
    end

    it "floors at zero" do
      hackr.set_stat!("slipstream_heat", 5)
      hackr.set_stat!("slipstream_heat_last_at", 60.minutes.ago.to_i)

      expect(hackr.slipstream_heat).to eq(0)
    end
  end

  describe ".routes_from" do
    it "returns active routes accessible by hackr" do
      route # ensure created
      results = described_class.routes_from(region: origin_region, hackr: hackr)
      expect(results).to include(route)
    end

    it "excludes routes above hackr clearance" do
      route.update!(min_clearance: 99)
      results = described_class.routes_from(region: origin_region, hackr: hackr)
      expect(results).not_to include(route)
    end
  end
end
