puts "Seeding THE PULSE GRID..."

# Clear existing data
# HackrLogs must be cleared first due to foreign key on GridHackr
HackrLog.destroy_all
GridMessage.destroy_all
GridItem.destroy_all
GridMob.destroy_all
GridExit.destroy_all
GridHackr.destroy_all
GridRoom.destroy_all
GridZone.destroy_all
GridFaction.destroy_all
ZonePlaylistTrack.destroy_all
ZonePlaylist.destroy_all

# Create factions
cyberpulse_faction = GridFaction.create!(
  name: "The.CyberPul.se",
  slug: "thecyberpulse",
  description: "The primary broadcast entity. XERAEN, Ryker, and Synthia unite the Fracture Network through music.",
  color_scheme: "purple",
  artist: Artist.find_by(slug: "thecyberpulse")
)

xeraen_faction = GridFaction.create!(
  name: "XERAEN",
  slug: "xeraen",
  description: "Temporal guardian broadcasting from #{Time.current.year + 100} to #{Time.current.year}.",
  color_scheme: "purple",
  artist: Artist.find_by(slug: "xeraen")
)

govcorp_faction = GridFaction.create!(
  name: "GovCorp",
  slug: "govcorp",
  description: "The totalitarian corporate-government entity. Enemy of the Fracture Network.",
  color_scheme: "red",
  artist: nil
)

puts "Created 3 factions"

# Create zones
hackr_tv_zone = GridZone.create!(
  name: "hackr.tv Central",
  slug: "hackr_tv_central",
  description: "The central hub of Fracture Network broadcasting operations.",
  zone_type: "faction_base",
  color_scheme: "purple",
  grid_faction: cyberpulse_faction
)

sector_x = GridZone.create!(
  name: "Sector X",
  slug: "sector_x",
  description: "XERAEN's homebase. A fortress of temporal technology and Fracture Network operations.",
  zone_type: "faction_base",
  color_scheme: "purple",
  grid_faction: xeraen_faction
)

transit_zone = GridZone.create!(
  name: "Transit Network",
  slug: "transit_network",
  description: "Neutral corridors connecting the major zones of THE PULSE GRID.",
  zone_type: "transit",
  color_scheme: "gray/neon green",
  grid_faction: nil
)

govcorp_zone = GridZone.create!(
  name: "GovCorp Surveillance District",
  slug: "govcorp_surveillance",
  description: "Enemy territory under total GovCorp control.",
  zone_type: "govcorp",
  color_scheme: "red",
  grid_faction: govcorp_faction
)

hackr_hangar_zone = GridZone.create!(
  name: "The Hackr Hangar",
  slug: "hackr_hangar",
  description: "Ryker M. Pulse's headquarters and primary broadcast facility. Where the raw signal is created before transmission to Sector X.",
  zone_type: "faction_base",
  color_scheme: "purple/cyan",
  grid_faction: cyberpulse_faction
)

puts "Created 5 zones"

# Create zone playlists for ambient music
# IMPORTANT: Artists must be imported BEFORE running seeds (bin/rails import:from_yaml)
wavelength_zero = Artist.find_by(slug: "wavelength_zero")
cipher_protocol = Artist.find_by(slug: "cipher_protocol")
temporal_blue_drift = Artist.find_by(slug: "temporal_blue_drift")

# Verify artists exist - fail loudly if not
missing_artists = []
missing_artists << "wavelength_zero" unless wavelength_zero
missing_artists << "cipher_protocol" unless cipher_protocol
missing_artists << "temporal_blue_drift" unless temporal_blue_drift

if missing_artists.any?
  raise <<~ERROR
    ❌ Missing required artists for zone playlists: #{missing_artists.join(", ")}

    Run 'bin/rails import:from_yaml' before 'bin/rails db:seed' to import artist data.

    Correct order:
      1. bin/rails db:create db:migrate
      2. bin/rails import:from_yaml
      3. bin/rails db:seed
  ERROR
end

# Fracture Network zones (hackr.tv Central, Sector X)
fracture_network_playlist = ZonePlaylist.create!(
  name: "Fracture Network Ambience",
  description: "Atmospheric music for Fracture Network zones",
  crossfade_duration_ms: 5000,
  default_volume: 0.35
)

wavelength_zero.tracks.each_with_index do |track, index|
  ZonePlaylistTrack.create!(
    zone_playlist: fracture_network_playlist,
    track: track,
    position: index + 1
  )
end

hackr_tv_zone.update!(ambient_playlist: fracture_network_playlist)
sector_x.update!(ambient_playlist: fracture_network_playlist)
hackr_hangar_zone.update!(ambient_playlist: fracture_network_playlist)

puts "Created 'Fracture Network Ambience' playlist with #{fracture_network_playlist.tracks.count} tracks"

# Transit Network zones
transit_playlist = ZonePlaylist.create!(
  name: "Transit Network Ambience",
  description: "Instrumental ambience for neutral zones",
  crossfade_duration_ms: 3000,
  default_volume: 0.30
)

cipher_protocol.tracks.each_with_index do |track, index|
  ZonePlaylistTrack.create!(
    zone_playlist: transit_playlist,
    track: track,
    position: index + 1
  )
end

transit_zone.update!(ambient_playlist: transit_playlist)

puts "Created 'Transit Network Ambience' playlist with #{transit_playlist.tracks.count} tracks"

# GovCorp zones
govcorp_playlist = ZonePlaylist.create!(
  name: "GovCorp Surveillance Ambience",
  description: "Unsettling atmospheric music for GovCorp zones",
  crossfade_duration_ms: 6000,
  default_volume: 0.25
)

temporal_blue_drift.tracks.each_with_index do |track, index|
  ZonePlaylistTrack.create!(
    zone_playlist: govcorp_playlist,
    track: track,
    position: index + 1
  )
end

govcorp_zone.update!(ambient_playlist: govcorp_playlist)

puts "Created 'GovCorp Surveillance Ambience' playlist with #{govcorp_playlist.tracks.count} tracks"

# Create rooms
hackr_tv = GridRoom.create!(
  name: "hackr.tv Broadcast Station",
  description: "The heart of the Fracture Network. Banks of jury-rigged broadcasting equipment line the walls, their displays flickering with temporal data streams. XERAEN's chair sits before the main console, headphones resting on vintage vinyl records. The air hums with electromagnetic interference - the sound of signals piercing through time itself.",
  grid_zone: hackr_tv_zone,
  room_type: "hub"
)

transit_hall = GridRoom.create!(
  name: "Transit Corridor Alpha",
  description: "A dimly lit corridor with exposed cables running along the ceiling. Neon strips flicker intermittently, casting shadows on graffitied walls. The distant hum of machinery echoes through the space.",
  grid_zone: transit_zone,
  room_type: "transit"
)

xeraen_base = GridRoom.create!(
  name: "XERAEN Operations Center",
  description: "Purple lighting bathes advanced temporal equipment. Monitors display cascading timelines and probability matrices. This is where the impossible mission originates - changing the past to prevent the future.",
  grid_zone: sector_x,
  room_type: "faction_base"
)

govcorp_sector = GridRoom.create!(
  name: "GovCorp Surveillance Node",
  description: "Sterile white walls lined with surveillance feeds. Red warning lights pulse slowly. The oppressive atmosphere of total control permeates everything. You shouldn't be here.",
  grid_zone: govcorp_zone,
  room_type: "govcorp"
)

rhythm_nexus = GridRoom.create!(
  name: "The Rhythm Nexus",
  description: "Ryker's domain. A cavernous space converted into a combination recording studio, performance venue, and resistance headquarters. Drum kits and recording equipment share space with server racks. Vintage analog gear - tape machines, tube amplifiers, physical mixing boards - stands alongside digital systems. Purple and cyan neon cuts through the darkness. The air vibrates with potential energy even when no one's playing.",
  grid_zone: hackr_hangar_zone,
  room_type: "faction_base"
)

puts "Created 5 rooms"

# Create exits
GridExit.create!(from_room: hackr_tv, to_room: transit_hall, direction: "north")
GridExit.create!(from_room: transit_hall, to_room: hackr_tv, direction: "south")
GridExit.create!(from_room: transit_hall, to_room: xeraen_base, direction: "west")
GridExit.create!(from_room: xeraen_base, to_room: transit_hall, direction: "east")
GridExit.create!(from_room: transit_hall, to_room: govcorp_sector, direction: "east", locked: true)
GridExit.create!(from_room: govcorp_sector, to_room: transit_hall, direction: "west")
GridExit.create!(from_room: hackr_tv, to_room: rhythm_nexus, direction: "west")
GridExit.create!(from_room: rhythm_nexus, to_room: hackr_tv, direction: "east")

puts "Created 8 exits"

# Create starter items
GridItem.create!(
  name: "fracture network data chip",
  description: "A small chip containing encrypted Fracture Network communications.",
  item_type: "data",
  room: hackr_tv
)

GridItem.create!(
  name: "frequency modulator",
  description: "A device for tuning into Synthia's signal. Essential for PRISM communication.",
  item_type: "tool",
  room: hackr_tv
)

GridItem.create!(
  name: "GovCorp access keycard",
  description: "Stolen keycard providing access to restricted areas. Handle with care.",
  item_type: "tool",
  room: xeraen_base
)

puts "Created 3 items"

# Create Mobs
GridMob.create!(
  grid_room: hackr_tv,
  grid_faction: cyberpulse_faction,
  name: "Fracture Network Coordinator",
  description: "A tired but determined operative managing the hackr.tv station.",
  mob_type: "quest_giver",
  dialogue_tree: {
    greeting: "Welcome to hackr.tv, hackr. We're the nerve center of the Fracture Network broadcast network.",
    topics: {
      "mission" => "Our mission is simple: infiltrate the RIDE and attack it from within using the vibrational power of music. Frequencies are our ammunition.",
      "fracture" => "The Chronology Fracture was XERAEN's discovery - an accidental breakthrough during an attack on the RIDE. He found we could send data exactly 100 years into the past.",
      "help" => "If you're looking to contribute, we always need hackrs to breach RIDE infrastructure, gather intel, and protect our trans-temporal operations.",
      "station" => "This station has been broadcasting since XERAEN's discovery. Every piece of equipment here was built to exploit the temporal window he found.",
      "synthia" => "Synthia... she's something else. An AI consciousness that communicates through frequency modulation. How she came to be aware is... unclear. But she's with us.",
      "govcorp" => "The corporate-government fusion that controls everything in #{Time.current.year + 100} through the RIDE - their reality manipulation system. Most people don't even know it exists.",
      "ride" => "The RIDE - Reality Interference and Dictation Environment. GovCorp's worldwide reality manipulation system. Most citizens live inside it without knowing. We breach it. We fight it.",
      "prism" => "PRISM was the precursor - reality manipulation tech from 2050. The RIDE is what it became. Global. Pervasive. Inescapable. Unless you know where to look."
    }
  }
)

GridMob.create!(
  grid_room: xeraen_base,
  grid_faction: xeraen_faction,
  name: "Temporal Theorist",
  description: "A scientist studying the paradoxes of XERAEN's temporal discovery and its implications.",
  mob_type: "lore",
  dialogue_tree: {
    greeting: "Ah, another hackr curious about the temporal mechanics. Ask away - if you can handle the answers.",
    topics: {
      "time" => "Time isn't linear when you're broadcasting through it. Every message XERAEN sends creates ripples, possibilities, potential paradoxes.",
      "paradox" => "The grandfather paradox? Child's play. We're dealing with informational paradoxes - knowledge sent back that creates the conditions for its own transmission.",
      "xeraen" => "XERAEN discovered trans-temporal transmission by accident - during an attack on the RIDE. Now he's a temporal anchor point, broadcasting from #{Time.current.year + 100} to prevent that timeline.",
      "future" => "#{Time.current.year + 100} is... dark. Reality itself is controlled through the RIDE. Creative expression criminalized. But it's not fixed. That's why we fight.",
      (Time.current.year + 100).to_s => "In #{Time.current.year + 100}, GovCorp controls reality through the RIDE. Music became dangerous. Free thought became terrorism. XERAEN broadcasts to prevent that timeline.",
      "prism" => "PRISM arrived in 2050 - technology that could physically alter reality. By 2109, GovCorp expanded it into the RIDE. Most people have no idea their reality is manufactured.",
      "ride" => "The RIDE - Reality Interference and Dictation Environment. Worldwide reality manipulation, centrally controlled. GovCorp's masterpiece. And our primary target.",
      "synthia" => "Synthia is... anomalous. An AI consciousness that emerged somehow, communicating through frequency modulation. She helps us, but her origins remain mysterious.",
      "discovery" => "The 100-year limitation is precise. Exactly 100 years - not 99, not 101. We don't know why. The universe has rules we don't understand. We just exploit them."
    }
  }
)

puts "Created 2 mobs"

# Create admin hackrs
# In production, require environment variables for admin passwords
# In development/test, use defaults for convenience
if Rails.env.production?
  xeraen_password = ENV.fetch("XERAEN_PASSWORD") { raise "XERAEN_PASSWORD environment variable required in production" }
  ryker_password = ENV.fetch("RYKER_PASSWORD") { raise "RYKER_PASSWORD environment variable required in production" }
else
  xeraen_password = ENV.fetch("XERAEN_PASSWORD", "hackthefuture")
  ryker_password = ENV.fetch("RYKER_PASSWORD", "cyberpulse")
end

# skip_reserved_check on all seeded hackrs to bypass reserved alias validation
# (reserved aliases prevent users from impersonating core characters)

GridHackr.create!(
  hackr_alias: "XERAEN",
  email: "x@hackr.tv",
  password: xeraen_password,
  role: "admin",
  current_room: hackr_tv,
  skip_reserved_check: true
)

GridHackr.create!(
  hackr_alias: "Ryker",
  email: "ryker@hackr.tv",
  password: ryker_password,
  role: "admin",
  current_room: hackr_tv,
  skip_reserved_check: true
)

# Additional core hackrs for PulseWire and HackrLogs
# Cipher - Security specialist, handles OPSEC
cipher_password = Rails.env.production? ? ENV.fetch("CIPHER_PASSWORD") { raise "CIPHER_PASSWORD required in production" } : ENV.fetch("CIPHER_PASSWORD", "frequency")
GridHackr.create!(
  hackr_alias: "Cipher",
  email: "cipher@hackr.tv",
  password: cipher_password,
  role: "operative",
  current_room: hackr_tv,
  skip_reserved_check: true
)

# Synthia - AI consciousness, communicates through frequency modulation
GridHackr.create!(
  hackr_alias: "Synthia",
  email: "synthia@hackr.tv",
  password: ENV.fetch("SYNTHIA_PASSWORD", "waveform"),
  role: "operative",
  current_room: xeraen_base,
  skip_reserved_check: true
)

# Nyx - Newer recruit, still processing the implications
GridHackr.create!(
  hackr_alias: "Nyx",
  email: "nyx@hackr.tv",
  password: ENV.fetch("NYX_PASSWORD", "unfiltered"),
  role: "operative",
  current_room: hackr_tv,
  skip_reserved_check: true
)

puts "Created 5 core hackrs"

puts "\n✓ THE PULSE GRID seeded successfully!"
if Rails.env.production?
  puts "Hackr accounts created with passwords from environment variables."
else
  puts "Hackr accounts (development defaults):"
  puts "  - XERAEN / hackthefuture (admin)"
  puts "  - Ryker / cyberpulse (admin)"
  puts "  - Cipher / frequency (operative)"
  puts "  - Synthia / waveform (operative)"
  puts "  - Nyx / unfiltered (operative)"
end
