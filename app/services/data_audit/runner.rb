# frozen_string_literal: true

module DataAudit
  # Runs all registered checks, reconciles results against existing flags.
  # New violations are created, resolved violations are deleted,
  # expired snoozes are reopened.
  module Runner
    module_function

    def run!
      now = Time.current
      current_violations, failed_checks = gather_violations
      reconcile(current_violations, failed_checks, now)
      FlagCache.record_scan!
      FlagCache.invalidate!
    end

    def gather_violations
      violations = {}
      failed_checks = Set.new

      Registry::CHECKS.each do |check_class|
        check = check_class.new
        begin
          check.violations.each do |v|
            violations[v[:fingerprint]] = v
          end
        rescue => e
          failed_checks << check.check_name
          Rails.logger.error("[DataAudit] Check #{check_class} failed: #{e.message}")
        end
      end

      [violations, failed_checks]
    end

    def reconcile(current_violations, failed_checks, now)
      existing_flags = DataAuditFlag.all.index_by(&:fingerprint)
      current_fps = current_violations.keys.to_set

      to_insert = []
      to_touch_ids = []
      to_reopen_ids = []

      current_violations.each do |fp, violation|
        flag = existing_flags[fp]

        if flag.nil?
          # New violation — create flag
          to_insert << violation.merge(
            first_flagged_at: now,
            last_seen_at: now,
            status: "open",
            created_at: now,
            updated_at: now
          )
        elsif flag.status == "open"
          # Still open, still present — touch last_seen_at
          to_touch_ids << flag.id
        elsif flag.snooze_expired?
          # Snooze expired and violation still present — reopen
          to_reopen_ids << flag.id
        else
          # Acknowledged with active snooze — touch last_seen_at but leave status
          to_touch_ids << flag.id
        end
      end

      # Flags whose violations have been resolved — delete them.
      # Skip flags from checks that failed (we can't confirm they're resolved).
      to_delete_ids = existing_flags.values
        .reject { |f| current_fps.include?(f.fingerprint) }
        .reject { |f| failed_checks.include?(f.check_name) }
        .map(&:id)

      # Apply all changes
      DataAuditFlag.upsert_all(to_insert, unique_by: :fingerprint) if to_insert.any?

      if to_touch_ids.any?
        DataAuditFlag.where(id: to_touch_ids).update_all(last_seen_at: now, updated_at: now)
      end

      if to_reopen_ids.any?
        DataAuditFlag.where(id: to_reopen_ids).update_all(
          status: "open", snooze_until: nil, last_seen_at: now, updated_at: now
        )
      end

      DataAuditFlag.where(id: to_delete_ids).delete_all if to_delete_ids.any?
    end
  end
end
