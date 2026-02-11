# Uplink Chat Channels
# ====================
# Seeds for the Uplink real-time chat system

puts "Seeding Uplink channels..."

channels = [
  {
    slug: "ambient",
    name: "#ambient",
    description: "Always-on ambient comms channel. Connect with other operatives anytime.",
    is_active: true,
    requires_livestream: false,
    slow_mode_seconds: 0,
    minimum_role: "operative"
  },
  {
    slug: "live",
    name: "#live",
    description: "Livestream-only comms channel. Active during live broadcasts.",
    is_active: true,
    requires_livestream: true,
    slow_mode_seconds: 3,
    minimum_role: "operative"
  }
]

channels.each do |channel_data|
  channel = ChatChannel.find_or_initialize_by(slug: channel_data[:slug])
  channel.assign_attributes(channel_data)
  if channel.save
    puts "  #{channel.new_record? ? "Created" : "Updated"} channel: #{channel.name}"
  else
    puts "  Failed to save channel #{channel_data[:slug]}: #{channel.errors.full_messages.join(", ")}"
  end
end

puts "Uplink channels seeded: #{ChatChannel.count} total"
