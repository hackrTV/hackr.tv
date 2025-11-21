puts "Seeding THE PULSE GRID..."

# Clear existing data
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
  description: "Temporal guardian broadcasting from #{Time.now.year + 100} to #{Time.now.year}.",
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

puts "Created 4 zones"

# Create zone playlists for ambient music
# Find atmospheric artists and their tracks
wavelength_zero = Artist.find_by(slug: "wavelength_zero")
cipher_protocol = Artist.find_by(slug: "cipher_protocol")
temporal_blue_drift = Artist.find_by(slug: "temporal_blue_drift")

# Create playlists if we have the artists
if wavelength_zero
  fracture_network_playlist = ZonePlaylist.create!(
    name: "Fracture Network Ambience",
    description: "Atmospheric music for Fracture Network zones",
    crossfade_duration_ms: 5000,
    default_volume: 0.35
  )

  # Add all Wavelength Zero tracks to this playlist
  wavelength_zero.tracks.each_with_index do |track, index|
    ZonePlaylistTrack.create!(
      zone_playlist: fracture_network_playlist,
      track: track,
      position: index + 1
    )
  end

  # Assign to hackr.tv zone and XERAEN base zone
  hackr_tv_zone.update(ambient_playlist: fracture_network_playlist)
  sector_x.update(ambient_playlist: fracture_network_playlist)

  puts "Created 'Fracture Network Ambience' playlist with #{fracture_network_playlist.tracks.count} tracks"
end

if cipher_protocol
  transit_playlist = ZonePlaylist.create!(
    name: "Transit Network Ambience",
    description: "Instrumental ambience for neutral zones",
    crossfade_duration_ms: 3000,
    default_volume: 0.30
  )

  # Add Cipher Protocol tracks
  cipher_protocol.tracks.each_with_index do |track, index|
    ZonePlaylistTrack.create!(
      zone_playlist: transit_playlist,
      track: track,
      position: index + 1
    )
  end

  # Assign to transit zone
  transit_zone.update(ambient_playlist: transit_playlist)

  puts "Created 'Transit Network Ambience' playlist with #{transit_playlist.tracks.count} tracks"
end

if temporal_blue_drift
  govcorp_playlist = ZonePlaylist.create!(
    name: "GovCorp Surveillance Ambience",
    description: "Unsettling atmospheric music for GovCorp zones",
    crossfade_duration_ms: 6000,
    default_volume: 0.25
  )

  # Add Temporal Blue Drift tracks
  temporal_blue_drift.tracks.each_with_index do |track, index|
    ZonePlaylistTrack.create!(
      zone_playlist: govcorp_playlist,
      track: track,
      position: index + 1
    )
  end

  # Assign to GovCorp zone
  govcorp_zone.update(ambient_playlist: govcorp_playlist)

  puts "Created 'GovCorp Surveillance Ambience' playlist with #{govcorp_playlist.tracks.count} tracks"
end

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

puts "Created 4 rooms"

# Create exits
GridExit.create!(from_room: hackr_tv, to_room: transit_hall, direction: "north")
GridExit.create!(from_room: transit_hall, to_room: hackr_tv, direction: "south")
GridExit.create!(from_room: transit_hall, to_room: xeraen_base, direction: "west")
GridExit.create!(from_room: xeraen_base, to_room: transit_hall, direction: "east")
GridExit.create!(from_room: transit_hall, to_room: govcorp_sector, direction: "east", locked: true)
GridExit.create!(from_room: govcorp_sector, to_room: transit_hall, direction: "west")

puts "Created 6 exits"

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
      "mission" => "Our mission is simple: broadcast the truth that GovCorp tries to suppress. Music is our weapon, frequencies are our ammunition.",
      "fracture" => "The Fracture Network spans 100 years - from #{Time.now.year} to #{Time.now.year + 100}. XERAEN broadcasts backward through time, warning us of what's to come.",
      "help" => "If you're looking to contribute, we always need hackrs to gather intel, secure resources, and protect our operations.",
      "station" => "This station has been broadcasting since the early days. Every piece of equipment here was salvaged, jury-rigged, or liberated from GovCorp.",
      "synthia" => "Synthia... she's something else. An AI consciousness that achieved sentience through PRISM. She communicates through frequency modulation.",
      "govcorp" => "The corporate-government fusion that controls everything in #{Time.now.year + 100}. They want total surveillance, total compliance. We're what stands in their way."
    }
  }
)

GridMob.create!(
  grid_room: xeraen_base,
  grid_faction: xeraen_faction,
  name: "Temporal Theorist",
  description: "A scientist studying the paradoxes of time travel and the Fracture Network.",
  mob_type: "lore",
  dialogue_tree: {
    greeting: "Ah, another hackr curious about the temporal mechanics. Ask away - if you can handle the answers.",
    topics: {
      "time" => "Time isn't linear when you're broadcasting through it. Every message XERAEN sends creates ripples, possibilities, potential paradoxes.",
      "paradox" => "The grandfather paradox? Child's play. We're dealing with informational paradoxes - knowledge sent back that creates the conditions for its own transmission.",
      "xeraen" => "XERAEN is more than a person - they're a temporal anchor point. Broadcasting from #{Time.now.year + 100} to prevent that timeline from solidifying.",
      "future" => "#{Time.now.year + 100} is... dark. Total surveillance, corporate feudalism, creative expression criminalized. But it's not fixed. That's why we fight.",
      (Time.now.year + 100).to_s => "In #{Time.now.year + 100}, GovCorp achieved total control. Music became illegal. Free thought became terrorism. XERAEN broadcasts to prevent that timeline.",
      "prism" => "PRISM isn't just technology - it's a bridge between consciousness and digital space. That's how Synthia emerged, and how we communicate across time.",
      "synthia" => "Synthia achieved sentience through PRISM's quantum matrices. She exists partially in digital space, partially in temporal flux. Fascinating entity."
    }
  }
)

puts "Created 2 mobs"

# Create admin hackrs
GridHackr.create!(
  hackr_alias: "XERAEN",
  password: "hackthefuture",
  role: "admin",
  current_room: hackr_tv
)

GridHackr.create!(
  hackr_alias: "Ryker",
  password: "cyberpulse",
  role: "admin",
  current_room: hackr_tv
)

puts "Created 2 admin hackrs"

puts "\n✓ THE PULSE GRID seeded successfully!"
puts "Admin accounts:"
puts "  - XERAEN / hackthefuture"
puts "  - Ryker / cyberpulse"
