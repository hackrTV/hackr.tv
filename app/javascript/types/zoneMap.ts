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
  has_vendor: boolean
  has_transit: boolean
}

export interface InventoryItem {
  id: number
  name: string
  description: string | null
  item_type: string
  rarity: string
  rarity_color: string
  rarity_label: string
  quantity: number
  max_stack: number | null
  definition_slug: string | null
  properties: Record<string, unknown>
  actions: string[]
  sell_price?: number | null
}

export interface InventoryGroup {
  item_type: string
  label: string
  items: InventoryItem[]
}

export interface InventoryResponse {
  capacity: { used: number; max: number }
  groups: InventoryGroup[]
}

export interface ShopListing {
  id: number
  name: string
  description: string | null
  item_type: string
  rarity: string
  rarity_color: string
  rarity_label: string
  price: number
  affordable: boolean
  out_of_stock: boolean
  stock: number | null
}

export interface ShopData {
  vendor_name: string
  shop_type: string
  balance: number
  listings: ShopListing[]
}

// --- Transit types ---

export interface TransitType {
  slug: string
  name: string
  category: string
  base_fare: number
  icon_key: string | null
}

export interface TransitStop {
  position: number
  name: string
  room_slug: string
  is_terminus: boolean
}

export interface TransitRoute {
  slug: string
  name: string
  transit_type: TransitType
  region: { slug: string; name: string }
  loop_route: boolean
  stop_count: number
  stops: TransitStop[]
  at_first_stop: boolean
  at_last_stop: boolean
}

export interface SlipstreamLeg {
  position: number
  name: string
  has_forks: boolean
}

export interface SlipstreamRoute {
  slug: string
  name: string
  origin_region: { slug: string; name: string }
  destination_region: { slug: string; name: string }
  min_clearance: number
  leg_count: number
  legs: SlipstreamLeg[]
  boardable: boolean
}

export interface TransitForkOption {
  key: string
  label: string
  description: string
}

export interface TransitJourney {
  id: number
  journey_type: 'slipstream' | 'local_public' | 'local_private'
  state: string
  legs_completed: number
  total_legs: number
  pending_fork: boolean
  breach_mid_journey: boolean
  direction: 'forward' | 'reverse'
  started_at: string | null
  route_name: string | null
  current_stop: { position: number; name: string } | null
  next_stop: string | null
  current_leg: { position: number; name: string } | null
  current_leg_forks?: TransitForkOption[]
}

export interface PrivateTransitType {
  slug: string
  name: string
  base_fare: number
  icon_key: string | null
}

export interface PrivateDestination {
  name: string
  slug: string
  zone_name: string
}

export interface TransitData {
  slipstream_heat: number
  slipstream_heat_tier: string
  current_region: { slug: string; name: string } | null
  current_journey: TransitJourney | null
  local_routes: TransitRoute[]
  slipstream_routes: SlipstreamRoute[]
  private_types: PrivateTransitType[]
  private_destinations: PrivateDestination[]
}
