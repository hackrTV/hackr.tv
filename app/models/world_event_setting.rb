# frozen_string_literal: true

# == Schema Information
#
# Table name: world_event_settings
# Database name: primary
#
#  id                       :integer          not null, primary key
#  simulator_enabled        :boolean          default(TRUE), not null
#  target_events_per_minute :integer          default(30), not null
#  visible                  :boolean          default(FALSE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class WorldEventSetting < ApplicationRecord
  validates :target_events_per_minute, numericality: {greater_than: 0, less_than_or_equal_to: 120}

  # Singleton pattern — one config row
  def self.current
    first_or_create!(target_events_per_minute: 12, simulator_enabled: true)
  end

  def self.target_rate
    current.target_events_per_minute
  end

  def self.simulator_enabled?
    current.simulator_enabled
  end

  def self.visible?
    current.visible
  end
end
