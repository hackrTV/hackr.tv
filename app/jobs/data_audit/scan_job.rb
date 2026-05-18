# frozen_string_literal: true

module DataAudit
  class ScanJob < ApplicationJob
    queue_as :default

    def perform
      DataAudit::Runner.run!
    rescue => e
      Rails.logger.error("[DataAudit::ScanJob] Failed: #{e.message}")
      raise
    end
  end
end
