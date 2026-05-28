# frozen_string_literal: true

module WorldEventFeed
  # Generates consistent simulated events from population accounts.
  # Each simulant tracks state so events are internally coherent —
  # e.g. a hackr who "reaches CL15" won't later appear at CL10.
  #
  # Called by WorldEventFeed::SimulatorJob on a recurring schedule.
  class Simulator
    # Weighted event type distribution. Higher weight = more frequent.
    EVENT_WEIGHTS = {
      "breach_completed" => 30,
      "clearance_up" => 15,
      "mission_accepted" => 15,
      "mission_completed" => 12,
      "achievement_unlocked" => 10,
      "rep_tier_changed" => 8,
      "wire_post" => 7,
      "hackr_registered" => 3
    }.freeze

    TOTAL_WEIGHT = EVENT_WEIGHTS.values.sum

    # Pool of mission names for simulation (supplements real DB missions)
    SIMULATED_MISSIONS = [
      "Signal Recovery", "Data Salvage", "Shard Retrieval", "Dead Drop",
      "Ghost Protocol", "Network Sweep", "Perimeter Check", "Cache Raid",
      "Trace Cleanup", "Uplink Tap", "Firmware Extract", "Cipher Burn",
      "Grid Walk", "Relay Ping", "Core Sample", "Dark Harvest",
      "Proxy Chain", "Wire Tap", "Node Audit", "Pulse Intercept",
      "Echo Trace", "Fracture Recon", "Drift Scan", "Breach Intel",
      "Sector Sweep", "Clearance Run", "Depot Raid", "Rig Calibration"
    ].freeze

    # Pool of BREACH template names for simulation
    SIMULATED_BREACHES = [
      "Corrupted Terminal Node", "Data Siphon Relay", "Derelict Access Point",
      "Signal Jammer Array", "GovCorp Firewall Node", "Checkpoint Auth Node",
      "Sector 7 Maintenance Node", "Deep Net Archive", "Blacksite Terminal",
      "RAINN Command Relay", "Cipher Lock Station", "PRISM Substation Core",
      "Vault Core Epsilon", "GovCorp Authorization Node", "Access Terminal Echo",
      "Corrupted Background Daemon", "Rogue Signal Burst", "Transit Checkpoint Ping"
    ].freeze

    BREACH_TIERS = %w[standard standard standard advanced advanced elite ambient].freeze

    # Pool of WIRE post content for simulation
    WIRE_POSTS = [
      "anyone mapped the lower levels of The Hollows yet?",
      "just found a Quantum Shard in the Underbelly. wild.",
      "GovCorp patrols are thick in the Narrows today",
      "new firmware dropped at the vendor in Gold Mile",
      "PSA: don't skip the rest pod after elite BREACHes",
      "looking for someone to trade Cipher Chips",
      "the transit routes through The Canyon are sketchy",
      "finally got my DECK repaired. that was expensive",
      "has anyone seen the new schematics at Forge's shop?",
      "hit ARCHITECT standing with Hackrcore today 💀",
      "the ambient encounters in The Underbelly are no joke",
      "first time in The Narrows. these exits are confusing",
      "pro tip: salvage everything before you sell",
      "running low on energy cells. where's the nearest vendor?",
      "just completed my first elite BREACH. hands shaking",
      "the Fracture Network rep grind is real",
      "anyone else getting detected on slipstream routes lately?",
      "found a rare drop from a standard BREACH. RNG blessed",
      "mining rig output seems lower this week",
      "GovCorp debt is brutal. avoid capture at all costs",
      "the bootloader tutorial doesn't prepare you for real BREACHes",
      "looking for a group to run The Canyon routes",
      "my den is finally stacked. 3 fixtures, full storage",
      "BLACKLISTED with GovCorp and proud of it",
      "does anyone know the fastest route from Lakeshore to The Bend?",
      "just saw someone at CL50+. how??",
      "the puzzle gates on elite templates are impossible",
      "sold my old DECK and upgraded. night and day difference",
      "rest pods saved my run. was at 3 HP",
      "first time fabricating. the ingredient grind is real"
    ].freeze

    # Achievement names for simulation
    SIMULATED_ACHIEVEMENTS = [
      "First Steps", "Grid Walker", "Grid Runner", "First Contact",
      "Data Acquired", "Scrapper", "Breaker of Circuits", "Signal Acquired",
      "Den Architect", "Pack Rat", "Rare Find", "Junk Dealer",
      "Data Streamer", "Channel Found", "Screen Tap"
    ].freeze

    FACTION_NAMES = [
      "The Fracture Network", "Hackrcore", "Blackout",
      "Frontwave", "Offline", "GovCorp"
    ].freeze

    REP_TIERS = %w[UNKNOWN TRUSTED OPERATIVE SPECIALIST ARCHITECT].freeze

    def initialize
      @simulants = WorldEventSimulant.includes(:grid_hackr).to_a
    end

    # Generate a single simulated event from a random simulant.
    # Returns the created WorldEvent, or nil on failure.
    def generate_event!
      return nil if @simulants.empty?

      simulant = @simulants.sample
      event_type = weighted_random_type

      case event_type
      when "clearance_up" then generate_clearance_up(simulant)
      when "mission_accepted" then generate_mission_accepted(simulant)
      when "mission_completed" then generate_mission_completed(simulant)
      when "breach_completed" then generate_breach_completed(simulant)
      when "rep_tier_changed" then generate_rep_tier_changed(simulant)
      when "achievement_unlocked" then generate_achievement_unlocked(simulant)
      when "hackr_registered" then generate_hackr_registered
      when "wire_post" then generate_wire_post(simulant)
      end
    rescue => e
      Rails.logger.error("[WorldEventFeed::Simulator] generate_event! failed: #{e.message}")
      nil
    end

    private

    def weighted_random_type
      roll = rand(TOTAL_WEIGHT)
      cumulative = 0
      EVENT_WEIGHTS.each do |type, weight|
        cumulative += weight
        return type if roll < cumulative
      end
      EVENT_WEIGHTS.keys.last
    end

    def generate_clearance_up(simulant)
      return generate_breach_completed(simulant) if simulant.clearance >= 99

      new_cl = simulant.clearance + 1
      simulant.advance_state!("clearance", new_cl)

      Publisher.publish(
        event_type: "clearance_up",
        hackr_alias: simulant.hackr_alias,
        data: {"new_clearance" => new_cl},
        simulated: true
      )
    end

    def generate_mission_accepted(simulant)
      mission_name = pick_mission(simulant)
      simulant.advance_state!("active_mission", mission_name)

      Publisher.publish(
        event_type: "mission_accepted",
        hackr_alias: simulant.hackr_alias,
        data: {"mission_name" => mission_name},
        simulated: true
      )
    end

    def generate_mission_completed(simulant)
      # If no active mission, accept and complete one
      mission_name = simulant.active_mission || pick_mission(simulant)
      completed = simulant.completed_missions + [mission_name]
      simulant.advance_state!("completed_missions", completed.last(20))
      simulant.advance_state!("active_mission", nil)

      Publisher.publish(
        event_type: "mission_completed",
        hackr_alias: simulant.hackr_alias,
        data: {"mission_name" => mission_name},
        simulated: true
      )
    end

    def generate_breach_completed(simulant)
      template_name = SIMULATED_BREACHES.sample
      tier = BREACH_TIERS.sample
      new_count = simulant.breach_count + 1
      simulant.advance_state!("breach_count", new_count)

      Publisher.publish(
        event_type: "breach_completed",
        hackr_alias: simulant.hackr_alias,
        data: {"template_name" => template_name, "tier" => tier},
        simulated: true
      )
    end

    def generate_rep_tier_changed(simulant)
      faction_name = FACTION_NAMES.sample
      direction = (rand < 0.8) ? "up" : "down"

      standings = simulant.faction_standings.dup
      current_idx = REP_TIERS.index(standings[faction_name]) || 0

      if direction == "up" && current_idx < REP_TIERS.length - 1
        new_tier = REP_TIERS[current_idx + 1]
      elsif direction == "down" && current_idx > 0
        new_tier = REP_TIERS[current_idx - 1]
      else
        new_tier = REP_TIERS[current_idx]
        direction = "up" # No actual change, just show current
      end

      standings[faction_name] = new_tier
      simulant.advance_state!("faction_standings", standings)

      Publisher.publish(
        event_type: "rep_tier_changed",
        hackr_alias: simulant.hackr_alias,
        data: {"faction_name" => faction_name, "new_tier" => new_tier, "direction" => direction},
        simulated: true
      )
    end

    def generate_achievement_unlocked(simulant)
      available = SIMULATED_ACHIEVEMENTS - simulant.achievements_earned
      if available.empty?
        # All achievements earned — fall back to breach
        return generate_breach_completed(simulant)
      end

      achievement_name = available.sample
      earned = simulant.achievements_earned + [achievement_name]
      simulant.advance_state!("achievements_earned", earned)

      Publisher.publish(
        event_type: "achievement_unlocked",
        hackr_alias: simulant.hackr_alias,
        data: {"achievement_name" => achievement_name},
        simulated: true
      )
    end

    def generate_hackr_registered
      # Use a random simulant as the "new registration" — won't repeat
      # aliases often with 125 simulants in the pool
      simulant = @simulants.sample
      Publisher.publish(
        event_type: "hackr_registered",
        hackr_alias: simulant.hackr_alias,
        data: {},
        simulated: true
      )
    end

    def generate_wire_post(simulant)
      Publisher.publish(
        event_type: "wire_post",
        hackr_alias: simulant.hackr_alias,
        data: {"content" => WIRE_POSTS.sample},
        simulated: true
      )
    end

    def pick_mission(simulant)
      # Avoid repeating recently completed missions
      available = SIMULATED_MISSIONS - simulant.completed_missions.last(5)
      available = SIMULATED_MISSIONS if available.empty?
      available.sample
    end
  end
end
