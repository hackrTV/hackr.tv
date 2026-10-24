module UplinkHelper
  # Packet.tsx PLATFORM_COLORS keys → CSS class suffixes.
  PLATFORM_CLASSES = {"TTV" => "ttv", "YT_" => "yt", "SYNTHIA" => "synthia"}.freeze

  # Packet.tsx parseBridgedContent: "[Platform] username: message".
  BRIDGED_CONTENT = /\A\[.+?\]\s*(.+?):\s(.+)\z/

  ROLE_BADGES = {"admin" => "ADMIN", "operator" => "OP"}.freeze

  # Links are allowed only for native admin packets — bridged/bot
  # packets always censor (Packet.tsx renderContent).
  def uplink_packet_text(packet, text = packet.content)
    UplinkTextRenderer.render(text,
      poster_is_admin: packet.source.nil? && packet.grid_hackr&.role == "admin")
  end

  def parse_bridged_packet(content)
    content.match(BRIDGED_CONTENT)
  end

  # Who sent it, as a short label: "@alias" for native packets,
  # "TTV username" for bridged ones, "SYNTHIA" for the bot. Shared by the
  # mention toast and the reply quote line. `parsed` is the bridged match
  # when the caller already has it.
  def uplink_packet_sender(packet, parsed = nil)
    return "SYNTHIA" if packet.source == "SYNTHIA"

    if packet.source.present?
      parsed ||= parse_bridged_packet(packet.content)
      return "#{packet.source} #{parsed[1]}" if parsed
    end

    "@#{packet.grid_hackr&.hackr_alias}"
  end

  # One-line plain-text excerpt of a packet (bridged packets lose their
  # "[Platform] user:" prefix); dropped packets read as redacted.
  def uplink_packet_excerpt(packet, parsed = nil, length: 80)
    return "[PACKET DROPPED]" if packet.dropped?

    parsed ||= parse_bridged_packet(packet.content) if packet.source.present? && packet.source != "SYNTHIA"
    (parsed ? parsed[2] : packet.content).to_s.squish.truncate(length)
  end

  def uplink_platform_class(source)
    PLATFORM_CLASSES[source]
  end

  def uplink_role_badge(role)
    ROLE_BADGES[role]
  end

  # Role → author/badge color class suffix; unknown roles fall back to
  # operative styling (Packet.tsx getRoleColor default).
  def uplink_role_class(role)
    GridHackr::ROLE_LEVELS.key?(role) ? role : "operative"
  end

  # Sidebar groups for the /uplink shell: [[category, [channels]], …] in
  # first-appearance order of an already `.ordered` list, so a category
  # sorts by its lowest-positioned channel.
  def uplink_channel_groups(channels)
    channels.group_by(&:category)
  end

  # Square live/offline dot for livestream channels (sidebar rows, popout
  # tabs, the shell's channel header).
  def uplink_live_dot(live)
    tag.span(class: class_names("channel-tab-dot", "channel-tab-dot--live": live), title: live ? "LIVE" : "Offline")
  end

  # Author identity for the packet-log controller's consecutive-author
  # grouping. Bridged packets all share the bridge's service hackr, so
  # the key carries the parsed platform username; Synthia is one bot.
  def uplink_author_key(packet, parsed = nil)
    if packet.source == "SYNTHIA"
      "bot"
    elsif packet.source.present?
      "#{packet.source}:#{parsed ? parsed[1] : packet.grid_hackr_id}"
    else
      "h#{packet.grid_hackr_id}"
    end
  end
end
