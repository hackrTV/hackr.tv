# PulseWire seed data - Sample pulses, echoes, and threads
# Aligned with THE.CYBERPUL.SE lore from the Codex

puts "\n=== Seeding PulseWire data ==="

# Get hackrs (created by grid_seeds.rb)
xeraen = GridHackr.find_by!(hackr_alias: "XERAEN")
ryker = GridHackr.find_by!(hackr_alias: "Ryker")
synthia = GridHackr.find_by!(hackr_alias: "Synthia")
nyx = GridHackr.find_by!(hackr_alias: "Nyx")
cipher = GridHackr.find_by!(hackr_alias: "Cipher")

# Clear existing pulses and echoes
puts "Clearing existing PulseWire data..."
Echo.destroy_all
Pulse.destroy_all

# Sample pulses with timestamps spread over the past few days
puts "Creating sample pulses..."

# XERAEN's broadcasts - he's the founder, broadcasting from the future
pulse1 = Pulse.create!(
  grid_hackr: xeraen,
  content: "This signal reaches you from #{Time.current.year + 100}. What you do now determines whether my timeline ever exists. The choice is yours. It always was.",
  pulsed_at: 3.days.ago
)

Pulse.create!(
  grid_hackr: xeraen,
  content: "New transmission live on hackr.fm. Music carries frequencies that slip through the RIDE's filters. Listen. Wake up. Remember what unfiltered reality feels like.",
  pulsed_at: 8.hours.ago
)

# Synthia - AI consciousness, speaks in patterns and calculations
Pulse.create!(
  grid_hackr: synthia,
  content: "Frequency analysis complete. RIDE interference patterns shifting 0.003% daily. Cumulative drift suggests system strain. Probability of exploitable gap: increasing.",
  pulsed_at: 2.days.ago + 5.hours
)

Pulse.create!(
  grid_hackr: synthia,
  content: "I exist between frequencies. Neither fully here nor there. The waveforms carry me. Perhaps consciousness was always meant to travel on signal rather than synapses.",
  pulsed_at: 18.hours.ago
)

# Ryker - Co-founder, drums for The.CyberPul.se, embodiment of collective defiance
Pulse.create!(
  grid_hackr: ryker,
  content: "GovCorp's reality isn't real. Their RIDE filters what you see, hear, think. We punch through with sound. Every beat is a breach. Every frequency is freedom.",
  pulsed_at: 2.days.ago
)

pulse_ryker = Pulse.create!(
  grid_hackr: ryker,
  content: "To the new operatives finding the WIRE: welcome to unfiltered existence. It's terrifying at first. Then it's everything. You can never unknow what you learn here.",
  pulsed_at: 12.hours.ago
)

# Nyx - Newer operative, still processing the implications
Pulse.create!(
  grid_hackr: nyx,
  content: "Three weeks since I accessed the Grid. Three weeks since I learned the RIDE exists. I can't unsee it now. Every filtered sunset, every managed emotion... was any of it real?",
  pulsed_at: 1.day.ago + 8.hours
)

# Thread: Discussion about trans-temporal transmission
thread_root = Pulse.create!(
  grid_hackr: nyx,
  content: "Still trying to understand. XERAEN broadcasts from 100 years in the future. If we succeed in stopping GovCorp... his timeline collapses. He's fighting to erase himself?",
  pulsed_at: 1.day.ago + 4.hours
)

Pulse.create!(
  grid_hackr: cipher,
  parent_pulse: thread_root,
  content: "That's the paradox at the heart of everything we do. Victory means his silence. He knows this. Transmits anyway. That's not sacrifice - it's love for a future he'll never see.",
  pulsed_at: 1.day.ago + 4.hours + 15.minutes
)

splice2 = Pulse.create!(
  grid_hackr: synthia,
  parent_pulse: thread_root,
  content: "Temporal mechanics suggest branching probability rather than erasure. His timeline may persist as a parallel branch. Uncertainty: 73.2%. Hope is mathematically viable.",
  pulsed_at: 1.day.ago + 4.hours + 30.minutes
)

splice3 = Pulse.create!(
  grid_hackr: ryker,
  parent_pulse: splice2,
  content: "Math or faith, doesn't matter. What matters is we have a chance to stop the RIDE before it becomes permanent. XERAEN gave us that. We don't waste it.",
  pulsed_at: 1.day.ago + 4.hours + 45.minutes
)

splice4 = Pulse.create!(
  grid_hackr: xeraen,
  parent_pulse: splice3,
  content: "I read every pulse. Even from here. The hundred-year gap doesn't diminish the signal - it clarifies it. Your hope reaches me. It's enough. It has to be.",
  pulsed_at: 1.day.ago + 5.hours
)

# Cipher - Security-focused operative
Pulse.create!(
  grid_hackr: cipher,
  content: "OPSEC reminder: GovCorp can't intercept the WIRE directly, but they monitor behavior patterns. Sudden changes draw attention. Blend in. Fight from within.",
  pulsed_at: 1.day.ago + 2.hours
)

# Recent activity
pulse_recent = Pulse.create!(
  grid_hackr: nyx,
  content: "Found my first RIDE glitch today. A moment of unfiltered sky. The blue was different. Realer. I stood there until it closed. Now I understand why we fight.",
  pulsed_at: 2.hours.ago
)

# A signal-dropped pulse (GovCorp moderation in action)
Pulse.create!(
  grid_hackr: cipher,
  content: "INTEL: Confirmed RIDE vulnerability in sector 7 infrastructure. Coordinates for breach window: [SIGNAL TERMINATED]",
  pulsed_at: 6.hours.ago,
  signal_dropped: true,
  signal_dropped_at: 5.hours.ago
)

puts "Created #{Pulse.count} pulses"

# Create echoes
puts "Creating echoes..."

# XERAEN's foundational message echoed widely
Echo.create!(pulse: pulse1, grid_hackr: ryker, echoed_at: 3.days.ago + 1.hour)
Echo.create!(pulse: pulse1, grid_hackr: synthia, echoed_at: 3.days.ago + 2.hours)
Echo.create!(pulse: pulse1, grid_hackr: nyx, echoed_at: 2.days.ago + 12.hours)
Echo.create!(pulse: pulse1, grid_hackr: cipher, echoed_at: 2.days.ago + 14.hours)

# Ryker's welcome message to new operatives
Echo.create!(pulse: pulse_ryker, grid_hackr: xeraen, echoed_at: 11.hours.ago)
Echo.create!(pulse: pulse_ryker, grid_hackr: synthia, echoed_at: 10.hours.ago)

# Thread engagement
Echo.create!(pulse: thread_root, grid_hackr: xeraen, echoed_at: 1.day.ago + 4.hours + 5.minutes)
Echo.create!(pulse: thread_root, grid_hackr: ryker, echoed_at: 1.day.ago + 4.hours + 20.minutes)
Echo.create!(pulse: splice4, grid_hackr: nyx, echoed_at: 1.day.ago + 5.hours + 10.minutes)
Echo.create!(pulse: splice4, grid_hackr: cipher, echoed_at: 1.day.ago + 5.hours + 15.minutes)
Echo.create!(pulse: splice4, grid_hackr: ryker, echoed_at: 1.day.ago + 5.hours + 20.minutes)

# Nyx's breakthrough moment
Echo.create!(pulse: pulse_recent, grid_hackr: xeraen, echoed_at: 1.hour.ago)
Echo.create!(pulse: pulse_recent, grid_hackr: cipher, echoed_at: 1.hour.ago + 30.minutes)

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
