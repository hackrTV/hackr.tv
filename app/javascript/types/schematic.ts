export interface SchematicIngredient {
  item_slug: string
  item_name: string
  rarity: string
  rarity_color: string
  required: number
  owned: number
}

export interface SchematicOutput {
  slug: string
  name: string
  rarity: string
  rarity_color: string
}

export interface Schematic {
  slug: string
  name: string
  description: string | null
  output: SchematicOutput
  output_quantity: number
  xp_reward: number
  required_clearance: number
  required_mission_slug: string | null
  required_achievement_slug: string | null
  required_room_type: string | null
  required_room_type_label: string | null
  ingredients: SchematicIngredient[]
  craftable: boolean
  has_ingredients: boolean
}

export interface SchematicsIndexResponse {
  schematics: Schematic[]
}
