# frozen_string_literal: true

module GridHackr::Transit
  extend ActiveSupport::Concern

  included do
    has_many :grid_transit_journeys, dependent: :destroy
  end

  def in_transit?
    grid_transit_journeys.where(state: "active").exists?
  end

  def active_journey
    grid_transit_journeys.where(state: "active")
      .includes(:grid_slipstream_route, :current_leg,
        :grid_transit_route, :current_stop)
      .first
  end

  # Read current slipstream heat with lazy decay applied.
  # Decay: 1 point per minute since last update.
  # NOTE: This has a DB write side-effect — decayed value is persisted on read
  # to avoid recalculating on every access. This means API GET endpoints that
  # call slipstream_heat are not purely read-only.
  def slipstream_heat
    raw = stat("slipstream_heat").to_i
    last_at = stat("slipstream_heat_last_at").to_i
    return raw if last_at.zero? || raw.zero?

    elapsed_minutes = ((Time.current.to_i - last_at) / 60.0).floor
    return raw if elapsed_minutes <= 0

    decayed = [raw - elapsed_minutes, 0].max
    if decayed < raw
      set_stat!("slipstream_heat", decayed)
      set_stat!("slipstream_heat_last_at", Time.current.to_i) if decayed > 0
    end
    decayed
  end

  def slipstream_heat_tier
    heat = slipstream_heat
    case heat
    when 0..9 then :cold
    when 10..40 then :warm
    when 41..70 then :hot
    else :burning
    end
  end

  def add_slipstream_heat!(amount)
    current = slipstream_heat # triggers decay first
    new_level = [current + amount, 100].min
    set_stat!("slipstream_heat", new_level)
    set_stat!("slipstream_heat_last_at", Time.current.to_i)
    new_level
  end
end
