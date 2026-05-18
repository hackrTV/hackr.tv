# frozen_string_literal: true

module ErrorTracker
  # Purges error occurrences older than the retention period.
  # Groups are preserved — occurrence_count is a lifetime total (intentional).
  # Errors propagate to Solid Queue for retry/reporting.
  class RetentionJob < ApplicationJob
    queue_as :default

    MIN_RETENTION = 7

    def perform
      days = [ENV.fetch("ERROR_TRACKER_RETENTION_DAYS", "90").to_i, MIN_RETENTION].max
      deleted = ErrorOccurrence.older_than(days).delete_all
      Rails.logger.info "[ErrorTracker::RetentionJob] Purged #{deleted} occurrences older than #{days} days"
    end
  end
end
