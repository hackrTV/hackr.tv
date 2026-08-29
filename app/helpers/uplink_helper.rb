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
end
