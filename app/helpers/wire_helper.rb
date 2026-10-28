# Role colors + badges come from UplinkHelper (uplink_role_class /
# uplink_role_badge) so a hackr reads the same on the WIRE and in chat
# (tokens.css --role-*; ledger redesign 2026-10).
module WireHelper
  def wire_text(pulse)
    WireTextRenderer.render(pulse.content, poster_is_admin: pulse.grid_hackr.role == "admin")
  end

  def bio_text(text)
    BioTextRenderer.render(text)
  end

  # One-line plain-text excerpt for the "[>] re @alias · …" quote line
  # on a splice row; a dropped parent reads as redacted.
  def wire_excerpt(pulse, length: 80)
    return "[PULSE DROPPED]" if pulse.pulse_dropped?

    pulse.content.to_s.squish.truncate(length)
  end

  # ProfileHeader.tsx formatLastActive (+ its 5-minute "online now" rule).
  def last_active_label(time)
    seconds = Time.current - time
    return "online now" if seconds < 5.minutes
    return "active #{(seconds / 60).floor}m ago" if seconds < 1.hour
    return "active #{(seconds / 1.hour).floor}h ago" if seconds < 1.day

    "active #{(seconds / 1.day).floor}d ago"
  end

  def watch_time_label(seconds)
    return "—" if seconds.to_i < 60

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    "#{hours}h #{minutes}m"
  end
end
