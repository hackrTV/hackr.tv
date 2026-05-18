# frozen_string_literal: true

# == Schema Information
#
# Table name: performance_metrics
# Database name: telemetry
#
#  id              :integer          not null, primary key
#  connection_type :string(32)
#  device_class    :string(16)
#  metric_name     :string           not null
#  metric_type     :string           not null
#  page_path       :string           not null
#  unit            :string           not null
#  value           :float            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  hackr_id        :integer
#  session_id      :string(64)
#
# Indexes
#
#  index_performance_metrics_on_created_at   (created_at)
#  index_performance_metrics_on_metric_name  (metric_name)
#
class PerformanceMetric < TelemetryRecord
  VALID_METRIC_NAMES = %w[LCP INP CLS FCP TTFB zone_map_render panel_open page_nav].freeze
  VALID_METRIC_TYPES = %w[web_vital component navigation].freeze

  validates :metric_name, inclusion: {in: VALID_METRIC_NAMES}
  validates :metric_type, inclusion: {in: VALID_METRIC_TYPES}
  validates :value, presence: true, numericality: true
  validates :unit, inclusion: {in: %w[ms score]}
  validates :page_path, presence: true, length: {maximum: 255}

  scope :recent, -> { order(created_at: :desc) }
  scope :web_vitals, -> { where(metric_type: "web_vital") }
  scope :slow_renders, -> { where(metric_name: "zone_map_render").where("value > ?", 500) }
  scope :older_than, ->(days) { where("created_at < ?", days.days.ago) }
end
