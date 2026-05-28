# frozen_string_literal: true

# == Schema Information
#
# Table name: world_event_simulants
# Database name: primary
#
#  id            :integer          not null, primary key
#  state         :json             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_world_event_simulants_on_grid_hackr_id  (grid_hackr_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class WorldEventSimulant < ApplicationRecord
  belongs_to :grid_hackr

  validates :grid_hackr_id, uniqueness: true

  delegate :hackr_alias, to: :grid_hackr

  # Convenience accessors for state JSON keys
  def clearance
    state["clearance"] || 0
  end

  def breach_count
    state["breach_count"] || 0
  end

  def completed_missions
    state["completed_missions"] || []
  end

  def active_mission
    state["active_mission"]
  end

  def faction_standings
    state["faction_standings"] || {}
  end

  def achievements_earned
    state["achievements_earned"] || []
  end

  def deck_name
    state["deck_name"]
  end

  # Advance a single state key and persist
  def advance_state!(key, value)
    new_state = (state || {}).merge(key.to_s => value)
    update_column(:state, new_state)
    self.state = new_state
  end
end
