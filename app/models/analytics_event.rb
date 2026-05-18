# frozen_string_literal: true

# == Schema Information
#
# Table name: analytics_events
# Database name: telemetry
#
#  id         :integer          not null, primary key
#  event_name :string           not null
#  event_type :string           not null
#  properties :text
#  created_at :datetime         not null
#  hackr_id   :integer
#  session_id :string(36)       not null
#
# Indexes
#
#  index_analytics_events_on_created_at  (created_at)
#  index_analytics_events_on_event_type  (event_type)
#  index_analytics_events_on_session_id  (session_id)
#
class AnalyticsEvent < TelemetryRecord
  EVENT_TYPES = %w[page_view feature_click button_click panel_open panel_close
    command_entered session_start session_end].freeze

  validates :event_type, inclusion: {in: EVENT_TYPES}
  validates :event_name, :session_id, presence: true

  scope :older_than, ->(days) { where("created_at < ?", days.days.ago) }
end
