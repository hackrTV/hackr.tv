# frozen_string_literal: true

module Grid
  # Gathers the public, countable stats shown on a hackr's WIRE profile
  # header. Every value is a vanity counter, so a short cache keeps
  # profile views cheap without hammering the DB on each hit. Bust is by
  # natural expiry — staleness up to CACHE_TTL is acceptable here.
  class ProfileStats
    CACHE_TTL = 5.minutes

    def self.for(hackr)
      new(hackr).to_h
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def to_h
      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: 30.seconds) do
        {
          pulses: pulses_count,
          echoes_received: echoes_received,
          packets: @hackr.chat_messages.count,
          achievements: @hackr.grid_hackr_achievements.count,
          breaches_completed: @hackr.stat("breach_completed_count").to_i,
          watch_seconds: @hackr.watch_sessions.sum(:accumulated_seconds)
        }
      end
    end

    private

    def cache_key
      "profile/v1/stats/hackr:#{@hackr.id}"
    end

    # Root pulses only — matches the wire_pulses_count achievement metric.
    def pulses_count
      @hackr.pulses.where(parent_pulse_id: nil).count
    end

    # Clout: how many times others have echoed this hackr's pulses.
    def echoes_received
      @hackr.pulses.sum(:echo_count)
    end
  end
end
