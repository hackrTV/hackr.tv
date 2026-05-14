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
