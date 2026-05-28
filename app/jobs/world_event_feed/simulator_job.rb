# frozen_string_literal: true

module WorldEventFeed
  # Recurring job that generates simulated world events at a dynamic rate.
  # Runs every 30 seconds. Measures organic event rate and fills the gap
  # to reach the configured target events per minute.
  #
  # If organic activity exceeds the target, emits zero simulated events.
  class SimulatorJob < ApplicationJob
    queue_as :default

    def perform
      return unless WorldEventSetting.simulator_enabled? && WorldEventSetting.visible?

      target = WorldEventSetting.target_rate
      organic_rate = Publisher.current_organic_rate

      # How many simulated events/min needed to reach target
      deficit = target - organic_rate
      return if deficit <= 0

      # We run every 30s = 2 times per minute. Emit our share of the deficit
      # per tick, with some randomness to avoid mechanical feel.
      events_this_tick = (deficit / 2.0).ceil
      # Add variance: ±30%
      variance = (events_this_tick * 0.3).ceil
      events_this_tick = rand((events_this_tick - variance)..(events_this_tick + variance))
      events_this_tick = events_this_tick.clamp(0, 20) # Safety cap per tick

      return if events_this_tick <= 0

      simulator = Simulator.new
      events_this_tick.times { simulator.generate_event! }
    rescue => e
      Rails.logger.error("[WorldEventFeed::SimulatorJob] failed: #{e.message}")
    end
  end
end
