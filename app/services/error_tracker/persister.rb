# frozen_string_literal: true

module ErrorTracker
  # Synchronously persists an error occurrence and updates its group.
  # Uses create_or_find_by! for race-safe group upsert and insert_all
  # for the occurrence row. Two SQLite writes per error (~1ms each).
  module Persister
    module_function

    def record(attrs)
      now = Time.current

      group = ErrorGroup.create_or_find_by!(fingerprint: attrs[:fingerprint]) do |g|
        g.title = attrs[:title]
        g.component = attrs[:component]
        g.severity = attrs[:severity]
        g.status = "open"
        g.first_seen_at = now
        g.last_seen_at = now
        g.occurrence_count = 0
      end

      # Auto-reopen resolved groups on recurrence
      if group.status == "resolved"
        group.update!(status: "open", resolved_at: nil, resolved_by_hackr_id: nil)
      end

      # Skip if actively ignored (not expired)
      if group.status == "ignored" && !group.ignore_expired?
        return
      end

      # Reopen expired ignores
      if group.ignore_expired?
        group.update!(status: "open", ignore_until: nil)
      end

      # Insert occurrence
      ErrorOccurrence.insert_all([{
        error_group_id: group.id,
        occurred_at: attrs[:occurred_at] || now,
        component: attrs[:component],
        exception_class: attrs[:exception_class],
        message: attrs[:message],
        backtrace: attrs[:backtrace],
        request_url: attrs[:request_url],
        request_method: attrs[:request_method],
        request_params: attrs[:request_params],
        ip_address: attrs[:ip_address],
        user_agent: attrs[:user_agent],
        hackr_id: attrs[:hackr_id],
        hackr_alias: attrs[:hackr_alias],
        rails_env: attrs[:rails_env],
        metadata: attrs[:metadata],
        created_at: now
      }])

      # Atomic counter increment
      ErrorGroup.where(id: group.id).update_all(
        ["occurrence_count = occurrence_count + 1, last_seen_at = MAX(COALESCE(last_seen_at, ?), ?), first_seen_at = MIN(COALESCE(first_seen_at, ?), ?)",
          now, now, now, now]
      )
    end
  end
end
