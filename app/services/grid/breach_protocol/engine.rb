# frozen_string_literal: true

module Grid
  module BreachProtocol
    # Handles per-protocol-type behavior during the system turn.
    # Each protocol type has a tick! method that fires its effect.
    module Engine
      REROUTE_FIZZLE_CHANCE = 0.30

      # Called once per protocol during the system turn.
      # Returns an array of HTML message strings for display.
      def self.tick!(protocol, breach)
        return [] if protocol.destroyed?

        # Advance charging protocols
        if protocol.state == "charging"
          return advance_charge!(protocol)
        end

        # Fire active protocols
        return [] unless protocol.state == "active"

        # Reroute: skip this tick, queue fizzle check for next tick
        if protocol.rerouted?
          return handle_reroute!(protocol)
        end

        # Fizzle check: protocol was rerouted last round, now retrying
        if protocol.meta["fizzle_check"]
          return handle_fizzle!(protocol, breach)
        end

        fire_protocol!(protocol, breach)
      end

      # Default weakness category for each protocol type.
      # Revealed via analyze at level 2.
      def self.weakness_for(protocol_type)
        {
          "trace" => "offensive",
          "feedback" => "offensive",
          "lock" => "defensive",
          "adapt" => "utility",
          "spike" => "defensive",
          "purge" => "utility"
        }[protocol_type.to_s]
      end

      # --- Private class methods ---

      def self.fire_protocol!(protocol, breach)
        case protocol.protocol_type
        when "trace"
          tick_trace!(protocol, breach)
        when "feedback"
          tick_feedback!(protocol, breach)
        when "lock"
          tick_lock!(protocol, breach)
        when "adapt"
          tick_adapt!(protocol, breach)
        when "spike"
          tick_spike!(protocol, breach)
        when "purge"
          tick_purge!(protocol, breach)
        else
          []
        end
      end
      private_class_method :fire_protocol!

      def self.handle_reroute!(protocol)
        protocol.update_columns(rerouted: false, meta: protocol.meta.merge("fizzle_check" => true))
        [reroute_msg("Protocol [#{protocol.position + 1}] REROUTED — delayed.")]
      end
      private_class_method :handle_reroute!

      def self.handle_fizzle!(protocol, breach)
        new_meta = protocol.meta.except("fizzle_check")
        protocol.update_columns(meta: new_meta)

        if rand < REROUTE_FIZZLE_CHANCE
          [reroute_msg("Protocol [#{protocol.position + 1}] fizzled on retry!")]
        else
          fire_protocol!(protocol, breach)
        end
      end
      private_class_method :handle_fizzle!

      def self.advance_charge!(protocol)
        new_rounds = protocol.rounds_charging + 1
        if new_rounds >= protocol.charge_rounds
          protocol.update!(state: "active", rounds_charging: new_rounds)
          [alert_msg("#{protocol.type_label} protocol [#{protocol.position + 1}] ACTIVATED.")]
        else
          protocol.update!(rounds_charging: new_rounds)
          []
        end
      end
      private_class_method :advance_charge!

      # TRACE: detection contribution handled by BreachService#end_round!
      # via counting active trace protocols. The tick itself is a no-op
      # for active trace — its presence is what matters.
      def self.tick_trace!(protocol, breach)
        [info_msg("TRACE [#{protocol.position + 1}] cycling — detection accelerating.")]
      end
      private_class_method :tick_trace!

      # FEEDBACK: drains PSYCHE and ENERGY each round when active.
      def self.tick_feedback!(protocol, breach)
        hackr = breach.grid_hackr
        damage = 8
        psyche_drain = (damage / 2.0).ceil
        energy_drain = damage / 2
        hackr.adjust_vital!("psyche", -psyche_drain)
        hackr.adjust_vital!("energy", -energy_drain)
        [fire_msg("FEEDBACK [#{protocol.position + 1}] FIRING → PSYCHE -#{psyche_drain}, ENERGY -#{energy_drain}")]
      end
      private_class_method :tick_feedback!

      # LOCK: drains inspiration and reduces available actions.
      def self.tick_lock!(protocol, breach)
        drain = 15
        old_inspiration = breach.inspiration
        new_inspiration = [old_inspiration - drain, 0].max
        breach.update!(inspiration: new_inspiration)
        [fire_msg("LOCK [#{protocol.position + 1}] FIRING → INSPIRATION -#{old_inspiration - new_inspiration}")]
      end
      private_class_method :tick_lock!

      # ADAPT: after 3 rounds active, mutates a random living protocol's weakness.
      # On low-tier encounters (ambient/standard), requires 3+ active TRACE protocols.
      def self.tick_adapt!(protocol, breach)
        rounds_active = protocol.meta["rounds_active"].to_i + 1
        protocol.update!(meta: protocol.meta.merge("rounds_active" => rounds_active))

        return [] unless rounds_active >= 3 && (rounds_active % 3).zero?

        # Low-tier gate: ambient/standard encounters need TRACE chain to enable ADAPT
        tier = breach.grid_breach_template.tier
        if %w[ambient standard].include?(tier)
          trace_count = breach.grid_breach_protocols.alive.where(protocol_type: "trace", state: "active").count
          return [] unless trace_count >= 3
        end

        target = breach.grid_breach_protocols
          .where.not(state: "destroyed")
          .where.not(id: protocol.id)
          .order("RANDOM()").first

        return [] unless target

        new_weakness = %w[offensive defensive utility].sample
        target.update!(weakness: new_weakness, meta: target.meta.merge("adapted" => true))
        [adapt_msg("ADAPT [#{protocol.position + 1}] MUTATED → Protocol [#{target.position + 1}] weakness shifted.")]
      end
      private_class_method :tick_adapt!

      # SPIKE: direct HEALTH drain — rare, dangerous. HEALTH 0 = worst failure.
      def self.tick_spike!(protocol, breach)
        hackr = breach.grid_hackr
        damage = 6
        hackr.adjust_vital!("health", -damage)
        [spike_msg("SPIKE [#{protocol.position + 1}] FIRING → HEALTH -#{damage}")]
      end
      private_class_method :tick_spike!

      # PURGE: stair-step reward degradation. Each active PURGE compounds.
      def self.tick_purge!(protocol, breach)
        new_multiplier = (breach.reward_multiplier * 0.90).round(4)
        breach.update!(reward_multiplier: new_multiplier)
        pct = (new_multiplier * 100).round
        [purge_msg("PURGE [#{protocol.position + 1}] FIRING → Rewards degraded to #{pct}%")]
      end
      private_class_method :tick_purge!

      def self.alert_msg(text)
        "<span style='color: #f87171; font-weight: bold;'>⚠ #{text}</span>"
      end
      private_class_method :alert_msg

      def self.fire_msg(text)
        "<span style='color: #f87171;'>#{text}</span>"
      end
      private_class_method :fire_msg

      def self.info_msg(text)
        "<span style='color: #9ca3af;'>#{text}</span>"
      end
      private_class_method :info_msg

      def self.adapt_msg(text)
        "<span style='color: #a78bfa;'>#{text}</span>"
      end
      private_class_method :adapt_msg

      def self.spike_msg(text)
        "<span style='color: #dc2626; font-weight: bold;'>#{text}</span>"
      end
      private_class_method :spike_msg

      def self.purge_msg(text)
        "<span style='color: #8b5cf6;'>#{text}</span>"
      end
      private_class_method :purge_msg

      def self.reroute_msg(text)
        "<span style='color: #22d3ee;'>#{text}</span>"
      end
      private_class_method :reroute_msg
    end
  end
end
