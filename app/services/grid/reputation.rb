# frozen_string_literal: true

module Grid
  # Tier ladder and thresholds for reputation display.
  #
  # Thresholds are inclusive lower bounds. Ordered ascending so Reputation.tier_for
  # can pick via reverse-scan.
  module Reputation
    TIERS = [
      {key: :blacklisted, label: "BLACKLISTED", min: -1000, color: "#dc2626"},
      {key: :hostile, label: "HOSTILE", min: -599, color: "#ef4444"},
      {key: :flagged, label: "FLAGGED", min: -199, color: "#f97316"},
      {key: :unknown, label: "UNKNOWN", min: -49, color: "#9ca3af"},
      {key: :trusted, label: "TRUSTED", min: 50, color: "#34d399"},
      {key: :operative, label: "OPERATIVE", min: 200, color: "#22d3ee"},
      {key: :specialist, label: "SPECIALIST", min: 500, color: "#a78bfa"},
      {key: :architect, label: "ARCHITECT", min: 800, color: "#fbbf24"}
    ].freeze

    MIN_VALUE = GridHackrReputation::MIN_VALUE
    MAX_VALUE = GridHackrReputation::MAX_VALUE

    def self.tier_for(value)
      v = value.to_i
      TIERS.reverse_each { |t| return t if v >= t[:min] }
      TIERS.first
    end

    def self.next_tier_for(value)
      current = tier_for(value)
      idx = TIERS.index(current)
      return nil if idx.nil? || idx == TIERS.length - 1
      TIERS[idx + 1]
    end
  end
end
