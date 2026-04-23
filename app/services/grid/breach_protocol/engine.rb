# frozen_string_literal: true

module Grid
  module BreachProtocol
    # Handles per-protocol-type behavior during the system turn.
    # Each protocol type has a tick! method that fires its effect.
    # Phase 2 adds SPIKE and PURGE as new `when` branches.
    module Engine
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

        case protocol.protocol_type
        when "trace"
          tick_trace!(protocol, breach)
        when "feedback"
          tick_feedback!(protocol, breach)
        when "lock"
          tick_lock!(protocol, breach)
        when "adapt"
          tick_adapt!(protocol, breach)
        else
          []
        end
      end

      # Default weakness category for each protocol type.
      # Revealed via analyze at level 2.
      def self.weakness_for(protocol_type)
        {
          "trace" => "offensive",
          "feedback" => "offensive",
          "lock" => "defensive",
          "adapt" => "utility"
        }[protocol_type.to_s]
      end

      # --- Private class methods ---

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
      def self.tick_adapt!(protocol, breach)
        rounds_active = protocol.meta["rounds_active"].to_i + 1
        protocol.update!(meta: protocol.meta.merge("rounds_active" => rounds_active))

        return [] unless rounds_active >= 3 && (rounds_active % 3).zero?

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
    end
  end
end
