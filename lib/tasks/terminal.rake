# frozen_string_literal: true

namespace :terminal do
  desc "List recent terminal sessions"
  task sessions: :environment do
    since = (ENV["SINCE"] || 24).to_i.hours.ago
    limit = (ENV["LIMIT"] || 50).to_i

    scope = TerminalSession.since(since)
    scope = scope.by_ip(ENV["IP"]) if ENV["IP"].present?
    scope = scope.by_hackr(ENV["HACKR"].to_i) if ENV["HACKR"].present?

    sessions = scope.order(connected_at: :desc).limit(limit).includes(:grid_hackr)

    if sessions.empty?
      puts "No sessions found."
      next
    end

    puts "%-6s %-16s %-20s %-20s %-10s %-8s %s" % [
      "ID", "IP", "Connected", "Disconnected", "Duration", "Reason", "Hackr"
    ]
    puts "-" * 110

    sessions.each do |s|
      hackr_name = s.grid_hackr&.hackr_alias || "-"
      disconnected = s.disconnected_at&.strftime("%Y-%m-%d %H:%M:%S") || "(active)"
      duration = s.duration_seconds ? "#{s.duration_seconds}s" : "-"

      puts format("%-6d %-16s %-20s %-20s %-10s %-8s %s",
        s.id,
        s.ip_address || "-",
        s.connected_at.strftime("%Y-%m-%d %H:%M:%S"),
        disconnected,
        duration,
        s.disconnect_reason || "-",
        hackr_name)
    end

    puts "\nTotal: #{sessions.size} session(s)"
  end

  desc "Show events for a terminal session"
  task events: :environment do
    session_id = ENV["SESSION_ID"]
    unless session_id.present?
      puts "Usage: bin/rails terminal:events SESSION_ID=<id>"
      next
    end

    session = TerminalSession.find_by(id: session_id)
    unless session
      puts "Session #{session_id} not found."
      next
    end

    events = session.terminal_events.order(:created_at)

    puts "Session ##{session.id} — #{session.ip_address || "unknown IP"}"
    puts "Connected: #{session.connected_at}"
    puts "Disconnected: #{session.disconnected_at || "(active)"}"
    puts "Hackr: #{session.grid_hackr&.hackr_alias || "-"}"
    puts ""

    puts "%-6s %-20s %-16s %-20s %s" % [
      "ID", "Time", "Type", "Handler", "Input"
    ]
    puts "-" * 90

    events.each do |e|
      puts format("%-6d %-20s %-16s %-20s %s",
        e.id,
        e.created_at.strftime("%Y-%m-%d %H:%M:%S"),
        e.event_type,
        e.handler || "-",
        e.input || "-")
    end

    puts "\nTotal: #{events.size} event(s)"
  end

  desc "Flag suspicious terminal activity"
  task flag: :environment do
    since = (ENV["SINCE"] || 24).to_i.hours.ago
    flags = []

    # Rule 1: IPs with >10 sessions in window (rapid reconnects)
    TerminalSession.since(since)
      .group(:ip_address)
      .having("COUNT(*) > 10")
      .count
      .each do |ip, count|
        flags << "[RAPID RECONNECT] #{ip}: #{count} sessions in window"
      end

    # Rule 2: IPs with >3 auth failures in window
    TerminalEvent.since(since)
      .auth_failures
      .joins(:terminal_session)
      .group("terminal_sessions.ip_address")
      .having("COUNT(*) > 3")
      .count
      .each do |ip, count|
        flags << "[AUTH BRUTE FORCE] #{ip}: #{count} auth failures in window"
      end

    # Rule 3: Sessions with >100 commands in any 1-minute span
    TerminalEvent.since(since)
      .commands
      .select("terminal_session_id, strftime('%Y-%m-%d %H:%M', created_at) AS minute_bucket, COUNT(*) AS cmd_count")
      .group("terminal_session_id, minute_bucket")
      .having("cmd_count > 100")
      .each do |row|
        flags << "[COMMAND SPAM] Session ##{row.terminal_session_id}: #{row.cmd_count} commands in minute #{row.minute_bucket}"
      end

    if flags.empty?
      puts "No suspicious activity detected since #{since.strftime("%Y-%m-%d %H:%M")}."
    else
      puts "=== Suspicious Activity Flags ==="
      puts ""
      flags.each { |f| puts "  #{f}" }
      puts ""
      puts "Total: #{flags.size} flag(s)"

      if ENV["EMAIL"] != "false"
        TerminalMailer.suspicious_activity(flags, since: since).deliver_now
        puts "\nAlert email sent to x@hackr.tv"
      end
    end
  end

  desc "Prune old terminal audit data"
  task prune: :environment do
    days = (ENV["DAYS"] || 90).to_i
    cutoff = days.days.ago

    # Delete events older than cutoff first
    event_count = TerminalEvent.where("created_at < ?", cutoff).delete_all

    # Only delete sessions that have no remaining events (avoids FK violation
    # for long-lived sessions whose newer events survived the cutoff)
    session_count = TerminalSession
      .where("connected_at < ?", cutoff)
      .where.not(id: TerminalEvent.select(:terminal_session_id))
      .delete_all

    puts "Pruned #{event_count} events and #{session_count} sessions older than #{days} days."
  end
end
