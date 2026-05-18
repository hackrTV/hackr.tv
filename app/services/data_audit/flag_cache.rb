# frozen_string_literal: true

module DataAudit
  module FlagCache
    OPEN_COUNT_KEY = "data_audit/open_count"
    LAST_SCAN_KEY = "data_audit/last_scan_at"
    TTL = 5.minutes

    module_function

    def open_count
      Rails.cache.fetch(OPEN_COUNT_KEY, expires_in: TTL) do
        DataAuditFlag.effective_open.count
      end
    end

    def last_scan_at
      Rails.cache.read(LAST_SCAN_KEY)
    end

    def record_scan!
      Rails.cache.write(LAST_SCAN_KEY, Time.current)
    end

    def invalidate!
      Rails.cache.delete(OPEN_COUNT_KEY)
    end
  end
end
