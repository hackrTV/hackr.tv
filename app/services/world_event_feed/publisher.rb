# frozen_string_literal: true

module WorldEventFeed
  # Single entry point for all world event publishing. Writes to the DB,
  # broadcasts over ActionCable, and tracks the organic event rate.
  #
  # Used by:
  #   - Organic hooks in game services (achievements, missions, breaches, etc.)
  #   - WorldEventFeed::Simulator (simulated population events)
  #   - Admin panel manual publish
  #   - External admin API (Synthia)
  class Publisher
    STREAM_NAME = "world_event_feed"

    # Publish a world event. Never raises — logs and swallows errors so
    # callers (game services) are never disrupted by feed failures.
    def self.publish(event_type:, hackr_alias:, data: {}, simulated: false)
      event = WorldEvent.create!(
        event_type: event_type,
        hackr_alias: hackr_alias,
        data: data,
        simulated: simulated
      )

      broadcast(event)
      track_organic_rate unless simulated
      event
    rescue => e
      Rails.logger.error("[WorldEventFeed] publish failed: #{e.message}")
      nil
    end

    # Convenience: publish a clearance_up event if the hackr leveled up.
    # Eliminates duplication across AchievementAwarder, MissionRewardGranter, BreachService.
    def self.publish_level_up(hackr_alias:, xp_result:)
      return unless xp_result&.dig(:leveled_up)
      publish(
        event_type: "clearance_up",
        hackr_alias: hackr_alias,
        data: {new_clearance: xp_result[:new_clearance]}
      )
    end

    # Canonical event serialization. Used by ActionCable broadcast, channel
    # hydration, and API responses. Single source of truth for the wire format.
    def self.serialize(event)
      {
        id: event.id,
        event_type: event.event_type,
        hackr_alias: event.hackr_alias,
        data: event.data,
        message: render_message(event),
        created_at: event.created_at.iso8601
      }
    end

    # Render a human-readable message for an event.
    def self.render_message(event)
      alias_str = event.hackr_alias
      d = event.data || {}

      case event.event_type
      when "clearance_up"
        "#{alias_str} reached CLEARANCE #{d["new_clearance"]}"
      when "mission_accepted"
        "#{alias_str} accepted mission: #{d["mission_name"]}"
      when "mission_completed"
        "#{alias_str} completed mission: #{d["mission_name"]}"
      when "breach_completed"
        "#{alias_str} completed #{d["tier"] || "standard"}-tier BREACH: #{d["template_name"]}"
      when "rep_tier_changed"
        direction = (d["direction"] == "down") ? "dropped to" : "reached"
        "#{alias_str} #{direction} #{d["new_tier"]} standing with #{d["faction_name"]}"
      when "achievement_unlocked"
        icon = d["badge_icon"].present? ? "#{d["badge_icon"]} " : ""
        "#{alias_str} unlocked #{icon}#{d["achievement_name"]}"
      when "hackr_registered"
        "#{alias_str} jacked into THE PULSE GRID for the first time"
      when "wire_post"
        content = d["content"].to_s.truncate(80)
        "#{alias_str} posted to THE WIRE: \"#{content}\""
      when "manual"
        d["message"].presence || "#{alias_str}: system event"
      else
        "#{alias_str}: #{event.event_type}"
      end
    end

    def self.broadcast(event)
      ActionCable.server.broadcast(STREAM_NAME, {
        type: "world_event",
        event: serialize(event)
      })
    rescue => e
      Rails.logger.error("[WorldEventFeed] broadcast failed: #{e.message}")
    end

    # Increment the organic event counter in cache for rate tracking.
    # Uses a per-minute bucket so the simulator can read a sliding window.
    def self.track_organic_rate
      bucket_key = "world_event_feed:organic:#{Time.current.strftime("%Y%m%d%H%M")}"
      Rails.cache.increment(bucket_key, 1, expires_in: 5.minutes)
    rescue => e
      Rails.logger.error("[WorldEventFeed] rate tracking failed: #{e.message}")
    end

    # Read the organic events/minute rate from cache buckets.
    # Looks at the current and previous minute buckets for a 2-minute window.
    def self.current_organic_rate
      now = Time.current
      current_key = "world_event_feed:organic:#{now.strftime("%Y%m%d%H%M")}"
      prev_key = "world_event_feed:organic:#{(now - 60).strftime("%Y%m%d%H%M")}"

      current_count = Rails.cache.read(current_key).to_i
      prev_count = Rails.cache.read(prev_key).to_i

      # Weight: full previous minute + fraction of current minute elapsed
      seconds_into_minute = now.sec
      weighted = prev_count + (current_count.to_f * 60 / [seconds_into_minute, 1].max)
      weighted.round(1)
    rescue => e
      Rails.logger.error("[WorldEventFeed] rate read failed: #{e.message}")
      0
    end
  end
end
