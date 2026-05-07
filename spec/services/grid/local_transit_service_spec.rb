# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::LocalTransitService do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room_a) { create(:grid_room, grid_zone: zone, name: "Stop A") }
  let(:room_b) { create(:grid_room, grid_zone: zone, name: "Stop B") }
  let(:room_c) { create(:grid_room, grid_zone: zone, name: "Stop C") }
  let(:hackr) { create(:grid_hackr, current_room: room_a) }

  let(:transit_type) { create(:grid_transit_type, :public_type) }
  let(:route) do
    create(:grid_transit_route, grid_transit_type: transit_type, grid_region: region).tap do |r|
      create(:grid_transit_stop, grid_transit_route: r, grid_room: room_a, position: 0, is_terminus: true)
      create(:grid_transit_stop, grid_transit_route: r, grid_room: room_b, position: 1)
      create(:grid_transit_stop, grid_transit_route: r, grid_room: room_c, position: 2, is_terminus: true)
    end
  end

  let!(:burn_cache) { create(:grid_cache, :burn) }
  let(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }

  def fund_cache(target_cache, amount)
    source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: source, to_cache: target_cache, amount: amount,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  before do
    fund_cache(cache, 1000)
  end

  describe ".board!" do
    it "creates an active journey for public transit" do
      result = described_class.board!(hackr: hackr, route: route)

      expect(result.journey).to be_a(GridTransitJourney)
      expect(result.journey.state).to eq("active")
      expect(result.journey.journey_type).to eq("local_public")
      expect(result.journey.current_stop.grid_room).to eq(room_a)
      expect(result.fare_charged).to eq(transit_type.base_fare)
      expect(result.display).to include("BOARDING")
    end

    it "deducts fare from hackr cache" do
      expect {
        described_class.board!(hackr: hackr, route: route)
      }.to change { hackr.default_cache.reload.balance }.by(-transit_type.base_fare)
    end

    it "raises AlreadyInJourney when hackr has active journey" do
      described_class.board!(hackr: hackr, route: route)
      expect {
        described_class.board!(hackr: hackr, route: route)
      }.to raise_error(Grid::LocalTransitService::AlreadyInJourney)
    end

    it "raises RouteNotAtStop when hackr is not at a stop on the route" do
      other_room = create(:grid_room, grid_zone: zone)
      hackr.update!(current_room: other_room)
      expect {
        described_class.board!(hackr: hackr, route: route)
      }.to raise_error(Grid::LocalTransitService::RouteNotAtStop)
    end

    it "raises InsufficientFunds when hackr cannot afford fare" do
      # Drain the cache by burning all funds
      Grid::TransactionService.burn!(from_cache: cache, amount: 1000, memo: "drain")
      expect {
        described_class.board!(hackr: hackr, route: route)
      }.to raise_error(Grid::LocalTransitService::InsufficientFunds)
    end
  end

  describe ".wait!" do
    before { described_class.board!(hackr: hackr, route: route) }

    it "advances to next stop and moves hackr" do
      result = described_class.wait!(hackr: hackr)

      expect(result.current_stop.grid_room).to eq(room_b)
      expect(hackr.reload.current_room).to eq(room_b)
      expect(result.arrived).to be false
    end

    it "shows arrival at end of line" do
      described_class.wait!(hackr: hackr) # A → B
      result = described_class.wait!(hackr: hackr) # B → C (end)

      expect(result.current_stop.grid_room).to eq(room_c)
      expect(hackr.reload.current_room).to eq(room_c)
    end

    it "auto-disembarks at end of non-loop route" do
      described_class.wait!(hackr: hackr) # A → B
      described_class.wait!(hackr: hackr) # B → C
      result = described_class.wait!(hackr: hackr) # C → end of line

      expect(result.arrived).to be true
      expect(result.journey.state).to eq("completed")
    end
  end

  describe ".disembark!" do
    before { described_class.board!(hackr: hackr, route: route) }

    it "completes journey at current stop" do
      described_class.wait!(hackr: hackr) # Move to B
      result = described_class.disembark!(hackr: hackr)

      expect(result.journey.state).to eq("completed")
      expect(result.room).to eq(room_b)
    end

    it "increments transit stats" do
      described_class.wait!(hackr: hackr)
      described_class.disembark!(hackr: hackr)

      expect(hackr.stat("local_transit_trips_count")).to eq(1)
    end
  end

  describe ".abandon!" do
    before { described_class.board!(hackr: hackr, route: route) }

    it "returns hackr to origin room and sets state to abandoned" do
      described_class.wait!(hackr: hackr) # Move to B
      result = described_class.abandon!(hackr: hackr)

      expect(result.journey.state).to eq("abandoned")
      expect(hackr.reload.current_room).to eq(room_a)
    end
  end

  describe "private transit" do
    let(:private_type) { create(:grid_transit_type, :private_type) }
    let(:private_route) do
      create(:grid_transit_route, grid_transit_type: private_type, grid_region: region).tap do |r|
        create(:grid_transit_stop, grid_transit_route: r, grid_room: room_a, position: 0)
        create(:grid_transit_stop, grid_transit_route: r, grid_room: room_b, position: 1)
        create(:grid_transit_stop, grid_transit_route: r, grid_room: room_c, position: 2)
      end
    end

    it "boards with destination and arrives in single wait" do
      dest_stop = private_route.grid_transit_stops.find_by(position: 2)
      result = described_class.board!(hackr: hackr, route: private_route, destination_stop: dest_stop)
      expect(result.journey.journey_type).to eq("local_private")

      wait_result = described_class.wait!(hackr: hackr)
      expect(wait_result.arrived).to be true
      expect(hackr.reload.current_room).to eq(room_c)
    end

    it "raises DestinationNotOnRoute without destination" do
      expect {
        described_class.board!(hackr: hackr, route: private_route)
      }.to raise_error(Grid::LocalTransitService::DestinationNotOnRoute)
    end

    it "raises AlreadyAtDestination when destination is current stop" do
      dest_stop = private_route.grid_transit_stops.find_by(position: 0)
      expect {
        described_class.board!(hackr: hackr, route: private_route, destination_stop: dest_stop)
      }.to raise_error(Grid::LocalTransitService::AlreadyAtDestination)
    end

    it "scales fare by distance" do
      dest_stop = private_route.grid_transit_stops.find_by(position: 2)
      result = described_class.board!(hackr: hackr, route: private_route, destination_stop: dest_stop)
      # Distance is 2 stops, fare = base_fare * max(distance, 1)
      expect(result.fare_charged).to eq(private_type.base_fare * 2)
    end
  end

  describe ".routes_at_room" do
    it "returns routes that stop at the given room" do
      route # ensure created
      results = described_class.routes_at_room(room: room_a, hackr: hackr)
      expect(results).to include(route)
    end

    it "excludes inactive routes" do
      route.update!(active: false)
      results = described_class.routes_at_room(room: room_a, hackr: hackr)
      expect(results).to be_empty
    end
  end
end
