# frozen_string_literal: true

# == Schema Information
#
# Table name: world_events
# Database name: primary
#
#  id          :integer          not null, primary key
#  data        :json             not null
#  event_type  :string           not null
#  hackr_alias :string           not null
#  simulated   :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_world_events_on_created_at  (created_at)
#  index_world_events_on_event_type  (event_type)
#  index_world_events_on_simulated   (simulated)
#
class WorldEvent < ApplicationRecord
  EVENT_TYPES = %w[
    clearance_up
    mission_accepted
    mission_completed
    breach_completed
    rep_tier_changed
    achievement_unlocked
    hackr_registered
    wire_post
    manual
  ].freeze

  validates :event_type, presence: true, inclusion: {in: EVENT_TYPES}
  validates :hackr_alias, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :organic, -> { where(simulated: false) }
  scope :simulated, -> { where(simulated: true) }
  scope :since, ->(time) { where("created_at >= ?", time) }

  # Count organic events in the last N seconds for rate calculation
  def self.organic_rate_per_minute(window_seconds: 60)
    count = organic.since(window_seconds.seconds.ago).count
    (count.to_f / window_seconds * 60).round(1)
  end
end
