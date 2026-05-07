# frozen_string_literal: true

module Grid
  class SlipstreamService
    BoardResult = Data.define(:journey, :route, :first_leg, :display)
    ForkResult = Data.define(:journey, :leg, :chosen_option, :display)
    AdvanceResult = Data.define(:journey, :leg, :completed, :breach_triggered, :display)
    ArrivalResult = Data.define(:journey, :destination_room, :heat_applied, :display)
    AbandonResult = Data.define(:journey, :display)
    ResumeResult = Data.define(:journey, :continued, :display)
    StatusResult = Data.define(:journey, :display)

    class NotAtBoardingPoint < StandardError; end
    class AlreadyInJourney < StandardError; end
    class ClearanceRequired < StandardError; end
    class NotInJourney < StandardError; end
    class NotAwaitingFork < StandardError; end
    class AwaitingFork < StandardError; end
    class InvalidForkKey < StandardError; end
    class CorridorLockedOut < StandardError; end

    MIN_CLEARANCE = 15

    def self.board!(hackr:, route:)
      new(hackr).board!(route)
    end

    def self.choose_fork!(hackr:, fork_key:)
      new(hackr).choose_fork!(fork_key)
    end

    def self.advance_leg!(hackr:)
      new(hackr).advance_leg!
    end

    def self.abandon!(hackr:)
      new(hackr).abandon!
    end

    def self.status(hackr:)
      new(hackr).status
    end

    def self.handle_breach_resume!(hackr:)
      new(hackr).handle_breach_resume!
    end

    def self.routes_from(region:, hackr:)
      GridSlipstreamRoute.accessible_by(hackr)
        .where(origin_region: region)
        .includes(:origin_region, :destination_region, :origin_room, :destination_room, :grid_slipstream_legs)
        .ordered
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def board!(route)
      raise ClearanceRequired if @hackr.stat("clearance").to_i < route.min_clearance
      raise NotAtBoardingPoint unless @hackr.current_room_id == route.origin_room_id

      first_leg = route.first_leg
      raise StandardError, "Route has no legs" unless first_leg

      ActiveRecord::Base.transaction do
        @hackr.lock!
        raise AlreadyInJourney if @hackr.active_journey
        raise CorridorLockedOut if corridor_locked_out?(route)

        journey = GridTransitJourney.create!(
          grid_hackr: @hackr,
          journey_type: "slipstream",
          state: "active",
          origin_room: @hackr.current_room,
          grid_slipstream_route: route,
          current_leg: first_leg,
          pending_fork: first_leg.has_forks?,
          started_at: Time.current,
          meta: {"chosen_forks" => {}}
        )

        display = Grid::TransitRenderer.render_slipstream_board(journey, route, first_leg)
        BoardResult.new(journey: journey, route: route, first_leg: first_leg, display: display)
      end
    end

    def choose_fork!(fork_key)
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.slipstream?
      raise NotAwaitingFork unless journey.awaiting_fork?

      leg = journey.current_leg
      # Case-insensitive match — keys are stored uppercase but input may be lowercase
      fork_key = leg.option_keys.find { |k| k.casecmp?(fork_key) } || fork_key
      raise InvalidForkKey unless leg.option_keys.include?(fork_key)

      ActiveRecord::Base.transaction do
        journey.lock!
        forks = journey.chosen_forks.merge(leg.position.to_s => fork_key)
        journey.update!(
          pending_fork: false,
          meta: journey.meta.merge("chosen_forks" => forks, "current_fork" => fork_key)
        )

        option = leg.option_for(fork_key)
        display = Grid::TransitRenderer.render_fork_chosen(journey, leg, option)
        ForkResult.new(journey: journey.reload, leg: leg, chosen_option: option, display: display)
      end
    end

    def advance_leg!
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.slipstream?
      raise AwaitingFork if journey.awaiting_fork?

      route = journey.grid_slipstream_route
      current_leg = journey.current_leg

      ActiveRecord::Base.transaction do
        journey.lock!
        @hackr.lock!

        # Detection roll BEFORE heat increment — failed legs don't accumulate heat
        detection = detection_check!(journey, current_leg, route)

        if detection == :breach
          # Real BREACH started — freeze journey until resolved
          last_breach = @hackr.grid_hackr_breaches.order(created_at: :desc).first
          journey.update!(
            breach_mid_journey: true,
            meta: journey.meta.merge("triggering_breach_id" => last_breach&.id)
          )
          display = Grid::TransitRenderer.render_slipstream_breach(journey, current_leg)
          return AdvanceResult.new(journey: journey.reload, leg: current_leg, completed: false,
            breach_triggered: true, display: display)
        end

        if detection == :penalty
          # Detected but no BREACH (no deck / fried deck) — penalty applied, replay leg
          journey.update!(
            pending_fork: current_leg.has_forks?,
            meta: journey.meta.except("current_fork")
          )
          display = Grid::TransitRenderer.render_slipstream_penalty(journey, current_leg)
          return AdvanceResult.new(journey: journey.reload, leg: current_leg, completed: false,
            breach_triggered: false, display: display)
        end

        # Accumulate heat only on successful leg traversal
        heat_per_leg = (route.base_heat_cost.to_f / route.leg_count).ceil
        journey.update!(heat_accumulated: journey.heat_accumulated + heat_per_leg)

        # Advance to next leg
        next_leg = route.next_leg_after(current_leg)

        if next_leg
          journey.update!(
            current_leg: next_leg,
            legs_completed: journey.legs_completed + 1,
            pending_fork: next_leg.has_forks?,
            meta: journey.meta.except("current_fork")
          )
          display = Grid::TransitRenderer.render_leg_advanced(journey, next_leg)
          AdvanceResult.new(journey: journey.reload, leg: next_leg, completed: false,
            breach_triggered: false, display: display)
        else
          # Final leg complete — arrive
          arrive!(journey, route)
          display = Grid::TransitRenderer.render_slipstream_arrival(journey, route)
          AdvanceResult.new(journey: journey.reload, leg: current_leg, completed: true,
            breach_triggered: false, display: display)
        end
      end
    end

    def abandon!
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.slipstream?

      ActiveRecord::Base.transaction do
        journey.lock!
        @hackr.update!(current_room: journey.origin_room) if journey.origin_room
        journey.update!(state: "abandoned", ended_at: Time.current)
        display = Grid::TransitRenderer.render_slipstream_abandon(journey)
        AbandonResult.new(journey: journey.reload, display: display)
      end
    end

    def handle_breach_resume!
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.slipstream? && journey.breach_mid_journey?

      # Check the specific breach that triggered during this journey
      triggering_id = journey.meta["triggering_breach_id"]
      last_breach = if triggering_id
        @hackr.grid_hackr_breaches.find_by(id: triggering_id)
      else
        @hackr.grid_hackr_breaches.order(updated_at: :desc).first
      end
      breach_state = last_breach&.state

      ActiveRecord::Base.transaction do
        journey.lock!
        @hackr.lock!

        case breach_state
        when "success"
          # Survived — continue journey with extra heat
          @hackr.add_slipstream_heat!(5)
          journey.update!(breach_mid_journey: false)
          display = Grid::TransitRenderer.render_breach_survived(journey)
          ResumeResult.new(journey: journey.reload, continued: true, display: display)
        when "failure"
          # Failed — severity depends on heat
          heat = @hackr.slipstream_heat
          if heat >= 71
            eject!(journey, :fatal)
          elsif heat >= 41
            eject!(journey, :severe)
          else
            # Light — replay current leg with increased heat
            @hackr.add_slipstream_heat!(10)
            journey.update!(
              breach_mid_journey: false,
              pending_fork: journey.current_leg&.has_forks? || false,
              meta: journey.meta.except("current_fork")
            )
            display = Grid::TransitRenderer.render_breach_failed_replay(journey)
            ResumeResult.new(journey: journey.reload, continued: true, display: display)
          end
        when "jacked_out"
          # Jackout — treat as light failure
          @hackr.add_slipstream_heat!(8)
          journey.update!(
            breach_mid_journey: false,
            pending_fork: journey.current_leg&.has_forks? || false,
            meta: journey.meta.except("current_fork")
          )
          display = Grid::TransitRenderer.render_breach_jackout_resume(journey)
          ResumeResult.new(journey: journey.reload, continued: true, display: display)
        else
          # Unknown state — just clear the flag
          journey.update!(breach_mid_journey: false)
          ResumeResult.new(journey: journey, continued: true,
            display: "<span style='color: #9ca3af;'>Slipstream transit resumed.</span>")
        end
      end
    end

    def status
      journey = @hackr.active_journey
      raise NotInJourney unless journey&.active? && journey.slipstream?
      display = Grid::TransitRenderer.render_slipstream_status(journey, @hackr)
      StatusResult.new(journey: journey, display: display)
    end

    private

    # Returns :none, :penalty (detected but no BREACH — no deck/fried), or :breach
    def detection_check!(journey, leg, route)
      heat = @hackr.slipstream_heat
      fork_key = journey.meta["current_fork"]
      risk_modifier = fork_key ? (leg.option_for(fork_key)&.dig("risk_modifier").to_i) : 0

      base_chance = route.detection_risk_base / 100.0
      heat_bonus = heat * 0.003 # each heat point adds 0.3%
      fork_bonus = risk_modifier / 100.0

      total_chance = [base_chance + heat_bonus + fork_bonus, 0.0].max
      total_chance = [total_chance, 0.95].min # cap at 95%

      return :none unless rand < total_chance

      # Find a breach template for slipstream encounters
      template_slug = leg.breach_template_slug
      template = if template_slug.present?
        GridBreachTemplate.published.find_by(slug: template_slug)
      end

      # Fallback: find any ambient template at CL15+
      template ||= GridBreachTemplate.published.ambient
        .where("min_clearance <= ?", @hackr.stat("clearance").to_i)
        .sample

      return :none unless template

      deck = @hackr.equipped_deck
      unless deck
        apply_no_deck_penalty!(journey)
        return :penalty
      end

      if deck.deck_fried?
        apply_no_deck_penalty!(journey)
        return :penalty
      end

      Grid::BreachService.start_ambient!(hackr: @hackr, template: template)
      :breach
    rescue Grid::BreachService::AlreadyInBreach
      :none
    end

    def apply_corridor_lockout!(journey, duration)
      route = journey.grid_slipstream_route
      return unless route
      lockout_until = Time.current.to_i + duration
      @hackr.set_stat!("slip_lockout_#{route.slug}", lockout_until)
    end

    def corridor_locked_out?(route)
      lockout_until = @hackr.stat("slip_lockout_#{route.slug}").to_i
      lockout_until > 0 && Time.current.to_i < lockout_until
    end

    def corridor_lockout_remaining(route)
      lockout_until = @hackr.stat("slip_lockout_#{route.slug}").to_i
      return 0 if lockout_until <= 0
      remaining = lockout_until - Time.current.to_i
      [remaining, 0].max
    end

    def apply_no_deck_penalty!(journey)
      drain_vital_floored!("energy", -20)
      drain_vital_floored!("psyche", -20)
      @hackr.add_slipstream_heat!(15)
    end

    # Drain a vital but floor at 1 — transit can't kill you
    def drain_vital_floored!(vital, amount)
      current = @hackr.stat(vital).to_i
      clamped = [amount, -(current - 1)].max # ensure result >= 1
      @hackr.adjust_vital!(vital, clamped) if clamped < 0
    end

    def arrive!(journey, route)
      # Track zone boundary for BREACH ejection targeting
      old_room = @hackr.current_room
      dest = route.destination_room
      if old_room && old_room.grid_zone_id != dest.grid_zone_id
        @hackr.update!(current_room: dest, zone_entry_room_id: old_room.id)
      else
        @hackr.update!(current_room: dest)
      end
      @hackr.add_slipstream_heat!(journey.heat_accumulated)
      journey.update!(
        state: "completed",
        ended_at: Time.current,
        legs_completed: journey.legs_completed + 1,
        destination_room: route.destination_room
      )
      increment_slipstream_stats!(route)
    end

    CORRIDOR_LOCKOUT_SEVERE = 5.minutes.to_i
    CORRIDOR_LOCKOUT_FATAL = 10.minutes.to_i

    def eject!(journey, severity)
      origin = journey.origin_room
      @hackr.update!(current_room: origin) if origin

      case severity
      when :severe
        drain_vital_floored!("energy", -30)
        drain_vital_floored!("psyche", -30)
        drain_vital_floored!("health", -15)
        @hackr.add_slipstream_heat!(journey.heat_accumulated + 20)
        apply_corridor_lockout!(journey, CORRIDOR_LOCKOUT_SEVERE)
      when :fatal
        drain_vital_floored!("energy", -40)
        drain_vital_floored!("psyche", -40)
        drain_vital_floored!("health", -30)
        @hackr.add_slipstream_heat!(journey.heat_accumulated + 35)
        apply_corridor_lockout!(journey, CORRIDOR_LOCKOUT_FATAL)
      end

      journey.update!(state: "ejected", ended_at: Time.current)

      display = Grid::TransitRenderer.render_slipstream_ejection(journey, severity)
      ResumeResult.new(journey: journey.reload, continued: false, display: display)
    end

    def increment_slipstream_stats!(route)
      count = @hackr.stat("slipstream_trips_count").to_i + 1
      @hackr.set_stat!("slipstream_trips_count", count)

      # Track visited regions
      visited = @hackr.stat("visited_region_ids") || []
      dest_id = route.destination_region_id
      unless visited.include?(dest_id)
        visited += [dest_id]
        @hackr.set_stat!("visited_region_ids", visited)
        @hackr.set_stat!("regions_visited_count", visited.size)
      end
    end
  end
end
