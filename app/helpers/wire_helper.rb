module WireHelper
  ROLE_COLORS = {
    "admin" => "#ff4444",
    "operator" => "#c084fc",
    "operative" => "#22d3ee"
  }.freeze

  def wire_text(pulse)
    WireTextRenderer.render(pulse.content, poster_is_admin: pulse.grid_hackr.role == "admin")
  end

  def bio_text(text)
    BioTextRenderer.render(text)
  end

  # PulseCard.tsx formatTimestamp: relative under 7 days, "Mon D" after.
  def wire_timestamp(time)
    seconds = Time.current - time
    return "just now" if seconds < 60
    return "#{(seconds / 60).floor}m ago" if seconds < 1.hour
    return "#{(seconds / 1.hour).floor}h ago" if seconds < 1.day
    return "#{(seconds / 1.day).floor}d ago" if seconds < 7.days

    time.strftime("%b %-d")
  end

  def role_color(role)
    ROLE_COLORS.fetch(role, "#888")
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
