# frozen_string_literal: true

module GridHackr::Stats
  extend ActiveSupport::Concern

  MAX_CLEARANCE = 99

  # XP required to reach a given clearance level: floor(10 * level^2.1)
  # Fast early leveling, exponential grind later.
  # Capped at 99 (9/9 — The Chronology Fracture anniversary).
  def self.xp_for_clearance(level)
    return 0 if level <= 0
    (10 * (level**2.1)).floor
  end

  INVENTORY_BASE_SLOTS = 16

  STAT_DEFAULTS = {
    "xp" => 0,
    "clearance" => 0,
    "health" => 100,
    "energy" => 100,
    "psyche" => 100,
    "inspiration" => 0,
    "bonus_inventory_slots" => 0
  }.freeze

  included do
    after_initialize :initialize_stats, if: :new_record?
  end

  # Read a stat with default fallback (handles pre-migration hackrs with nil stats)
  def stat(key)
    (stats || {}).fetch(key.to_s, STAT_DEFAULTS[key.to_s])
  end

  # Merged view of all stats with defaults
  def current_stats
    STAT_DEFAULTS.merge(stats || {})
  end

  # Write a single stat key. Uses update_column to skip callbacks.
  def set_stat!(key, value)
    new_stats = (stats || {}).merge(key.to_s => value)
    update_column(:stats, new_stats)
    self.stats = new_stats
  end

  # --- Dialogue context (branching tree navigation) ---

  # Returns the current dialogue path for a mob (array of topic keys).
  def dialogue_path_for(mob)
    ctx = stat("dialogue_context")
    return [] unless ctx.is_a?(Hash)
    path = ctx[mob.id.to_s]
    path.is_a?(Array) ? path : []
  end

  # Set the current dialogue path for a mob.
  def set_dialogue_path(mob, path)
    ctx = stat("dialogue_context")
    ctx = {} unless ctx.is_a?(Hash)
    ctx[mob.id.to_s] = path
    set_stat!("dialogue_context", ctx)
  end

  # Clear dialogue context for a specific mob.
  def clear_dialogue_path(mob)
    ctx = stat("dialogue_context")
    return unless ctx.is_a?(Hash)
    ctx.delete(mob.id.to_s)
    set_stat!("dialogue_context", ctx)
  end

  # Effective inventory capacity: base slots + bonus from equipment
  def inventory_capacity
    INVENTORY_BASE_SLOTS + stat("bonus_inventory_slots").to_i
  end

  # Adjust a vital (health/energy/psyche/inspiration) clamped to 0..max.
  # Max defaults to 100 but may be raised by equipped gear via effective_max.
  def adjust_vital!(key, delta)
    current = stat(key)
    max = effective_max(key.to_s)
    clamped = (current + delta).clamp(0, max)
    set_stat!(key, clamped)
    clamped
  end

  # Grant XP and handle clearance level-ups.
  # Returns { xp_gained:, new_xp:, leveled_up:, new_clearance: }
  def grant_xp!(amount)
    old_clearance = stat("clearance")
    new_xp = stat("xp") + amount
    new_clearance = clearance_for_xp(new_xp)
    new_stats = (stats || {}).merge("xp" => new_xp, "clearance" => new_clearance)
    update_column(:stats, new_stats)
    self.stats = new_stats
    {xp_gained: amount, new_xp: new_xp, leveled_up: new_clearance > old_clearance, new_clearance: new_clearance}
  end

  # Calculate clearance level from total XP
  def clearance_for_xp(xp)
    level = 0
    while level < MAX_CLEARANCE && xp >= GridHackr::Stats.xp_for_clearance(level + 1)
      level += 1
    end
    level
  end

  private

  def initialize_stats
    self.stats ||= STAT_DEFAULTS.dup
  end
end
