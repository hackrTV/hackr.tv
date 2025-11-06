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

# Create factions
cyberpulse_faction = GridFaction.create!(
  name: "The.CyberPul.se",
  slug: "the_cyberpulse",
  description: "The primary broadcast entity. XERAEN, Ryker, and Synthia unite the resistance through music.",
  color_scheme: "purple",
  artist: Artist.find_by(slug: "thecyberpulse")
)

xeraen_faction = GridFaction.create!(
  name: "XERAEN",
  slug: "xeraen",
  description: "Temporal guardian broadcasting from 2125 to 2025.",
  color_scheme: "purple",
  artist: Artist.find_by(slug: "xeraen")
)

govcorp_faction = GridFaction.create!(
  name: "GovCorp",
  slug: "govcorp",
  description: "The totalitarian corporate-government entity. Enemy of the resistance.",
  color_scheme: "red",
  artist: nil
)

puts "Created 3 factions"

# Create zones
hackr_tv_zone = GridZone.create!(
  name: "hackr.tv Central",
  slug: "hackr_tv_central",
  description: "The central hub of resistance broadcasting operations.",
  zone_type: "faction_base",
  color_scheme: "purple",
  grid_faction: cyberpulse_faction
)

sector_x = GridZone.create!(
  name: "Sector X",
  slug: "sector_x",
  description: "XERAEN's homebase. A fortress of temporal technology and resistance operations.",
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

# Create rooms
hackr_tv = GridRoom.create!(
  name: "hackr.tv Broadcast Station",
  description: "The heart of the resistance. Banks of jury-rigged broadcasting equipment line the walls, their displays flickering with temporal data streams. XERAEN's chair sits before the main console, headphones resting on vintage vinyl records. The air hums with electromagnetic interference - the sound of signals piercing through time itself.",
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
  name: "resistance data chip",
  description: "A small chip containing encrypted resistance communications.",
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
  name: "Resistance Coordinator",
  description: "A tired but determined operative managing the hackr.tv station.",
  mob_type: "quest_giver"
)

GridMob.create!(
  grid_room: xeraen_base,
  grid_faction: xeraen_faction,
  name: "Temporal Theorist",
  description: "A scientist studying the paradoxes of time travel and resistance.",
  mob_type: "lore"
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
