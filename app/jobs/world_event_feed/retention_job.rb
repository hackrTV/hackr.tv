# frozen_string_literal: true

module WorldEventFeed
  # Daily cleanup of world events older than 7 days.
  class RetentionJob < ApplicationJob
    queue_as :default

    RETENTION_DAYS = 7

    def perform
      cutoff = RETENTION_DAYS.days.ago
      deleted = WorldEvent.where("created_at < ?", cutoff).delete_all
      Rails.logger.info("[WorldEventFeed::RetentionJob] purged #{deleted} events older than #{cutoff}")
    end
  end
end
