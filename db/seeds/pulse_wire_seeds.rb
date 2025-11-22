# PulseWire seed data - Sample pulses, echoes, and threads

puts "\n=== Seeding PulseWire data ==="

# Get existing hackrs (created by grid_seeds.rb)
xeraen = GridHackr.find_by(hackr_alias: "XERAEN") || GridHackr.first
ryker = GridHackr.find_by(hackr_alias: "Ryker") || GridHackr.second

# Create some additional test hackrs if they don't exist
synthia = GridHackr.find_or_create_by!(hackr_alias: "Synthia") do |h|
  h.password = "cyberpulse"
  h.role = "operative"
end

nyx = GridHackr.find_or_create_by!(hackr_alias: "Nyx") do |h|
  h.password = "cyberpulse"
  h.role = "operative"
end

cipher = GridHackr.find_or_create_by!(hackr_alias: "Cipher") do |h|
  h.password = "cyberpulse"
  h.role = "operative"
end

# Clear existing pulses and echoes
puts "Clearing existing PulseWire data..."
Echo.destroy_all
Pulse.destroy_all

# Sample pulses with timestamps spread over the past few days
puts "Creating sample pulses..."

# Standalone pulses
pulse1 = Pulse.create!(
  grid_hackr: xeraen,
  content: "Just intercepted some interesting GovCorp chatter on the encrypted bands. The Fracture Network might be onto something big.",
  pulsed_at: 3.days.ago
)

pulse2 = Pulse.create!(
  grid_hackr: synthia,
  content: "Frequency patterns shifting in unexpected ways. My signal processing algorithms detect... something. Calculating...",
  pulsed_at: 2.days.ago + 5.hours
)

pulse3 = Pulse.create!(
  grid_hackr: ryker,
  content: "PRISM surveillance protocols updated. All operators, maintain signal discipline. The Grid remembers.",
  pulsed_at: 2.days.ago
)

pulse4 = Pulse.create!(
  grid_hackr: nyx,
  content: "The temporal anomalies near Zone 7 are getting worse. Time doesn't flow right there anymore. Avoid if possible.",
  pulsed_at: 1.day.ago + 8.hours
)

# Thread example: Discussion about The Fracture Network
thread_root = Pulse.create!(
  grid_hackr: cipher,
  content: "Anyone else think The Fracture Network is planning something major? Their recruitment activity is off the charts.",
  pulsed_at: 1.day.ago + 4.hours
)

splice1 = Pulse.create!(
  grid_hackr: xeraen,
  parent_pulse: thread_root,
  content: "Been tracking their broadcasts. Definitely ramping up for an operation. Question is: what's the target?",
  pulsed_at: 1.day.ago + 4.hours + 15.minutes
)

splice2 = Pulse.create!(
  grid_hackr: synthia,
  parent_pulse: thread_root,
  content: "Temporal data patterns suggest correlation with Chronology Fracture. Probability of prevention attempt: 87.3%",
  pulsed_at: 1.day.ago + 4.hours + 30.minutes
)

splice3 = Pulse.create!(
  grid_hackr: ryker,
  parent_pulse: splice2,
  content: "Prevention implies they know what's coming. Time travel or precognition? Either way, that's dangerous territory.",
  pulsed_at: 1.day.ago + 4.hours + 45.minutes
)

splice4 = Pulse.create!(
  grid_hackr: nyx,
  parent_pulse: splice3,
  content: "Or they're the cause and playing 4D chess. Never trust freedom fighters who operate in shadows darker than GovCorp's.",
  pulsed_at: 1.day.ago + 5.hours
)

# More recent pulses
pulse5 = Pulse.create!(
  grid_hackr: synthia,
  content: "The Pulse Grid's ambient frequencies modulating in non-random patterns. Analyzing waveform for embedded data... 🎵",
  pulsed_at: 18.hours.ago
)

pulse6 = Pulse.create!(
  grid_hackr: cipher,
  content: "Reminder: OPSEC is life. Don't broadcast your location, don't brag about your tech, don't trust anyone completely. Stay ghost.",
  pulsed_at: 12.hours.ago
)

pulse7 = Pulse.create!(
  grid_hackr: xeraen,
  content: "New release live on hackr.fm - 'System Collapse'. This one goes out to all the operatives still fighting in the dark.",
  pulsed_at: 8.hours.ago
)

# Very recent pulse
pulse8 = Pulse.create!(
  grid_hackr: nyx,
  content: "Signal detected: unauthorized time-stream manipulation in Sector 12. Someone's messing with causality again. This never ends well.",
  pulsed_at: 2.hours.ago
)

# A signal-dropped pulse (example of GovCorp moderation)
dropped_pulse = Pulse.create!(
  grid_hackr: cipher,
  content: "CLASSIFIED INTEL: GovCorp's Project Oversight has full access to—",
  pulsed_at: 6.hours.ago,
  signal_dropped: true,
  signal_dropped_at: 5.hours.ago
)

puts "Created #{Pulse.count} pulses"

# Create echoes (likes/rebroadcasts)
puts "Creating echoes..."

# Pulse 1 echoed by multiple hackrs
Echo.create!(pulse: pulse1, grid_hackr: ryker, echoed_at: 3.days.ago + 1.hour)
Echo.create!(pulse: pulse1, grid_hackr: synthia, echoed_at: 3.days.ago + 2.hours)
Echo.create!(pulse: pulse1, grid_hackr: nyx, echoed_at: 2.days.ago + 12.hours)

# Thread root echoed
Echo.create!(pulse: thread_root, grid_hackr: xeraen, echoed_at: 1.day.ago + 4.hours + 5.minutes)
Echo.create!(pulse: thread_root, grid_hackr: nyx, echoed_at: 1.day.ago + 4.hours + 20.minutes)

# Recent pulse echoes
Echo.create!(pulse: pulse7, grid_hackr: synthia, echoed_at: 7.hours.ago)
Echo.create!(pulse: pulse7, grid_hackr: ryker, echoed_at: 6.hours.ago)
Echo.create!(pulse: pulse7, grid_hackr: cipher, echoed_at: 5.hours.ago)
Echo.create!(pulse: pulse7, grid_hackr: nyx, echoed_at: 4.hours.ago)

# Some pulses echo individual splices
Echo.create!(pulse: splice2, grid_hackr: cipher, echoed_at: 1.day.ago + 4.hours + 35.minutes)
Echo.create!(pulse: splice4, grid_hackr: xeraen, echoed_at: 1.day.ago + 5.hours + 10.minutes)

# Latest pulse echoed
Echo.create!(pulse: pulse8, grid_hackr: xeraen, echoed_at: 1.hour.ago)
Echo.create!(pulse: pulse8, grid_hackr: cipher, echoed_at: 1.hour.ago + 30.minutes)

puts "Created #{Echo.count} echoes"

# Display summary
puts "\n=== PulseWire Seed Summary ==="
puts "Total Pulses: #{Pulse.count}"
puts "  - Root pulses: #{Pulse.roots.count}"
puts "  - Splices (replies): #{Pulse.where.not(parent_pulse_id: nil).count}"
puts "  - Signal-dropped: #{Pulse.dropped.count}"
puts "Total Echoes: #{Echo.count}"
puts "Total Hackrs with pulses: #{GridHackr.joins(:pulses).distinct.count}"
puts "\nMost echoed pulse: \"#{Pulse.order(echo_count: :desc).first&.content&.truncate(50)}\" (#{Pulse.maximum(:echo_count)} echoes)"
puts "Longest thread: #{Pulse.where.not(thread_root_id: nil).group(:thread_root_id).count.values.max || 0} splices"
puts "\n=== PulseWire seeding complete! ==="
