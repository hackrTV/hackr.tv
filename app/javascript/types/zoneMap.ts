export interface ZoneMapRoom {
  id: number
  name: string
  slug: string
  room_type: string | null
  map_x: number
  map_y: number
  map_z: number
  zone_id: number
  zone_color: string
  visited: boolean
  is_current: boolean
  hackr_count: number
  hackr_aliases: string[]
}

export interface ZoneMapExit {
  from_room_id: number
  to_room_id: number
  direction: string
  locked: boolean
}

export interface ZoneMapGhostRoom {
  id: number
  name: string
  zone_id: number
  zone_name: string
  region_name: string
  local_room_id: number
  direction: string
}

export interface BreachEncounter {
  id: number
  name: string
  tier_label: string
  min_clearance: number
}

export interface DeckStatus {
  equipped: boolean
  fried: boolean
}

export interface ZoneMapData {
  zone: {
    id: number
    name: string
    slug: string
    danger_level: number
    region_id: number
    region_name: string
  }
  rooms: ZoneMapRoom[]
  exits: ZoneMapExit[]
  ghost_rooms: ZoneMapGhostRoom[]
  current_room_id: number
  z_levels: number[]
  z_level: number
  in_breach: boolean
  breach_encounters: BreachEncounter[]
  deck_status: DeckStatus
}
