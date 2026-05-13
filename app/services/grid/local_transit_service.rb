# frozen_string_literal: true

module Grid
  class LocalTransitService
    BoardResult = Data.define(:journey, :route, :current_stop, :fare_charged, :display)
    WaitResult = Data.define(:journey, :current_stop, :arrived, :display)
    DisembarkResult = Data.define(:journey, :room, :display)
    AbandonResult = Data.define(:journey, :display)
    StatusResult = Data.define(:journey, :display)

    class NotAtTransitStop < StandardError; end
    class RouteNotAtStop < StandardError; end
    class AlreadyInJourney < StandardError; end
    class InsufficientFunds < StandardError; end
    class DestinationNotOnRoute < StandardError; end
    class AlreadyAtDestination < StandardError; end
    class NotInJourney < StandardError; end

    def self.board!(hackr:, route:, destination_stop: nil)
      new(hackr).board!(route, destination_stop)
    end

    def self.wait!(hackr:)
      new(hackr).wait!
    end

    def self.disembark!(hackr:)
      new(hackr).disembark!
    end

    def self.abandon!(hackr:)
      new(hackr).abandon!
    end

    def self.status(hackr:)
      new(hackr).status
    end

    # Private transit types available at this room — derived from private routes
    # that have a stop at this room (routes define boarding points, not destinations)
    def self.private_types_at_room(room:, hackr:)
      return [] unless room.room_type == "transit"

      GridTransitType.where(category: "private").published
        .joins(grid_transit_routes: :grid_transit_stops)
        .where(grid_transit_stops: {grid_room_id: room.id})
        .where(grid_transit_routes: {active: true})
        .distinct
        .select { |t| hackr.stat("clearance").to_i >= t.min_clearance }
    end

    # All transit rooms in the same region as the given room (for private destinations)
    def self.private_destinations(room:)
      region = room.grid_zone&.grid_region
      return [] unless region

      # Exclude slipstream origin rooms — those are hidden access points, not taxi destinations
      slip_room_ids = GridSlipstreamRoute.active.where(origin_region: region).pluck(:origin_room_id)

      GridRoom.where(room_type: "transit")
        .joins(:grid_zone).where(grid_zones: {grid_region_id: region.id})
        .where.not(id: [room.id] + slip_room_ids)
        .includes(:grid_zone)
        .order(:name)
    end

    def self.board_private!(hackr:, transit_type:, destination_room:)
      new(hackr).board_private!(transit_type, destination_room)
    end

    # Public routes only — private transit is shown separately via private_types_at_room.
    # Uses subquery to avoid joins/includes on the same association (which would
    # filter preloaded stops to only the current room's stop, breaking stop_count).
    def self.routes_at_room(room:, hackr:)
      region = room.grid_zone&.grid_region
      return [] unless region

      route_ids = GridTransitStop.where(grid_room_id: room.id)
        .joins(grid_transit_route: :grid_transit_type)
        .where(grid_transit_routes: {active: true, grid_region_id: region.id})
        .where(grid_transit_types: {category: "public"})
        .pluck(:grid_transit_route_id)

      return [] if route_ids.empty?

      GridTransitRoute.where(id: route_ids)
        .includes(:grid_transit_type, :grid_region, grid_transit_stops: :grid_room)
        .select { |r| r.grid_transit_type.published? && hackr.stat("clearance").to_i >= r.grid_transit_type.min_clearance }
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def board!(route, destination_stop = nil)
      room = @hackr.current_room
      boarding_stop = route.stop_for_room(room)
      raise RouteNotAtStop unless boarding_stop

      type = route.grid_transit_type

      # Private: require destination on the same route
      if type.private_point?
        raise DestinationNotOnRoute unless destination_stop
        raise DestinationNotOnRoute unless destination_stop.grid_transit_route_id == route.id
        raise AlreadyAtDestination if destination_stop.id == boarding_stop.id
      end

      fare = compute_fare(route, boarding_stop, destination_stop)

      ActiveRecord::Base.transaction do
        @hackr.lock!
        raise AlreadyInJourney if @hackr.active_journey

        # Check balance and deduct fare inside transaction
        if fare > 0
          cache = @hackr.default_cache
          raise InsufficientFunds unless cache && cache.balance >= fare
          Grid::TransactionService.burn!(from_cache: cache, amount: fare, memo: "Transit fare: #{route.name}")
        end

        journey_type = type.private_point? ? "local_private" : "local_public"
        dest_room = destination_stop&.grid_room

        journey = GridTransitJourney.create!(
          grid_hackr: @hackr,
          journey_type: journey_type,
          state: "active",
          origin_room: room,
          destination_room: dest_room,
          grid_transit_route: route,
          current_stop: boarding_stop,
          fare_paid: fare,
          started_at: Time.current,
          meta: {}
        )

        display = Grid::TransitRenderer.render_board(journey, route, boarding_stop)
        BoardResult.new(journey: journey, route: route, current_stop: boarding_stop, fare_charged: fare, display: display)
      end
    end

    # Private transit — routes define boarding points, destinations are any transit room in region
    def board_private!(transit_type, destination_room)
      room = @hackr.current_room
      raise NotAtTransitStop unless room.room_type == "transit"

      # Validate a private route for this type has a stop at the current room
      has_route = GridTransitRoute.active
        .where(grid_transit_type: transit_type)
        .joins(:grid_transit_stops)
        .where(grid_transit_stops: {grid_room_id: room.id})
        .exists?
      raise NotAtTransitStop unless has_route

      raise AlreadyAtDestination if destination_room.id == room.id

      fare = transit_type.base_fare

      ActiveRecord::Base.transaction do
        @hackr.lock!
        raise AlreadyInJourney if @hackr.active_journey

        if fare > 0
          cache = @hackr.default_cache
          raise InsufficientFunds unless cache && cache.balance >= fare
          Grid::TransactionService.burn!(from_cache: cache, amount: fare, memo: "#{transit_type.name} fare")
        end

        journey = GridTransitJourney.create!(
          grid_hackr: @hackr,
          journey_type: "local_private",
          state: "active",
          origin_room: room,
          destination_room: destination_room,
          fare_paid: fare,
          started_at: Time.current,
          meta: {"transit_type_slug" => transit_type.slug}
        )

        display = Grid::TransitRenderer.render_private_board(journey, transit_type, destination_room)
        BoardResult.new(journey: journey, route: nil, current_stop: nil, fare_charged: fare, display: display)
      end
    end

    def wait!
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.local?

      route = journey.grid_transit_route
      current = journey.current_stop

      ActiveRecord::Base.transaction do
        journey.lock!

        # Private transit: single wait → arrive directly at destination
        if journey.local_private?
          dest_room = journey.destination_room
          if dest_room
            move_hackr_to_room!(dest_room)
            complete_journey!(journey)
            display = Grid::TransitRenderer.render_private_arrival(journey, dest_room)
            return WaitResult.new(journey: journey.reload, current_stop: nil, arrived: true, display: display)
          end
        end

        next_stop = route.next_stop_after(current)

        unless next_stop
          # End of line (non-loop) — auto-disembark at current stop
          complete_journey!(journey)
          display = Grid::TransitRenderer.render_end_of_line(journey, current)
          return WaitResult.new(journey: journey.reload, current_stop: current, arrived: true, display: display)
        end

        journey.update!(current_stop: next_stop)
        move_hackr_to_room!(next_stop.grid_room)

        arrived = journey.destination_room_id.present? && next_stop.grid_room_id == journey.destination_room_id
        complete_journey!(journey) if arrived

        display = Grid::TransitRenderer.render_wait(journey, next_stop, arrived, route)
        WaitResult.new(journey: journey.reload, current_stop: next_stop, arrived: arrived, display: display)
      end
    end

    def disembark!
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.local?

      ActiveRecord::Base.transaction do
        journey.lock!
        room = journey.current_stop.grid_room
        complete_journey!(journey)
        display = Grid::TransitRenderer.render_disembark(journey, room)
        DisembarkResult.new(journey: journey.reload, room: room, display: display)
      end
    end

    def abandon!
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.local?

      ActiveRecord::Base.transaction do
        journey.lock!
        # Return to origin room
        @hackr.update!(current_room: journey.origin_room) if journey.origin_room
        Grid::RoomVisitRecorder.record!(hackr: @hackr, room: journey.origin_room) if journey.origin_room
        journey.update!(state: "abandoned", ended_at: Time.current)
        display = Grid::TransitRenderer.render_abandon(journey)
        AbandonResult.new(journey: journey.reload, display: display)
      end
    end

    def status
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.local?
      display = Grid::TransitRenderer.render_local_status(journey)
      StatusResult.new(journey: journey, display: display)
    end

    private

    def compute_fare(route, boarding_stop, destination_stop)
      type = route.grid_transit_type
      if type.private_point? && destination_stop
        stops = route.grid_transit_stops.order(:position).to_a
        board_idx = stops.index { |s| s.id == boarding_stop.id } || 0
        dest_idx = stops.index { |s| s.id == destination_stop.id } || 0
        distance = (dest_idx - board_idx).abs
        type.base_fare * [distance, 1].max
      else
        type.base_fare
      end
    end

    # Move hackr to room, tracking zone boundary crossings for BREACH ejection
    def move_hackr_to_room!(room)
      old_room = @hackr.current_room
      if old_room && old_room.grid_zone_id != room.grid_zone_id
        @hackr.update!(current_room: room, zone_entry_room_id: old_room.id)
      else
        @hackr.update!(current_room: room)
      end
      Grid::RoomVisitRecorder.record!(hackr: @hackr, room: room)
    end

    def complete_journey!(journey)
      journey.update!(state: "completed", ended_at: Time.current)
      increment_transit_stats!
    end

    def increment_transit_stats!
      count = @hackr.stat("local_transit_trips_count").to_i + 1
      @hackr.set_stat!("local_transit_trips_count", count)
    end
  end
end
