# frozen_string_literal: true

# Prunes old performance metrics and analytics events from the telemetry DB.
# Errors propagate to Solid Queue for retry/reporting.
class TelemetryPruneJob < ApplicationJob
  queue_as :default

  MIN_RETENTION = 7

  def perform
    perf_days = [ENV.fetch("PERF_METRICS_RETENTION_DAYS", "30").to_i, MIN_RETENTION].max
    analytics_days = [ENV.fetch("ANALYTICS_RETENTION_DAYS", "90").to_i, MIN_RETENTION].max

    perf_deleted = PerformanceMetric.older_than(perf_days).delete_all
    analytics_deleted = AnalyticsEvent.older_than(analytics_days).delete_all

    Rails.logger.info "[TelemetryPruneJob] Purged #{perf_deleted} perf metrics (>#{perf_days}d), " \
                      "#{analytics_deleted} analytics events (>#{analytics_days}d)"
  end
end
