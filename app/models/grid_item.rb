# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id                      :integer          not null, primary key
#  description             :text
#  equipped_slot           :string
#  item_type               :string
#  name                    :string
#  properties              :json
#  quantity                :integer          default(1), not null
#  rarity                  :string
#  value                   :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  container_id            :integer
#  deck_id                 :integer
#  grid_hackr_id           :integer
#  grid_item_definition_id :integer          not null
#  grid_mining_rig_id      :integer
#  room_id                 :integer
#
# Indexes
#
#  index_grid_items_on_container_id                (container_id)
#  index_grid_items_on_deck_id                     (deck_id)
#  index_grid_items_on_grid_hackr_id               (grid_hackr_id)
#  index_grid_items_on_grid_item_definition_id     (grid_item_definition_id)
#  index_grid_items_on_grid_mining_rig_id          (grid_mining_rig_id)
#  index_grid_items_on_hackr_equipped_slot_unique  (grid_hackr_id,equipped_slot) UNIQUE WHERE equipped_slot IS NOT NULL
#
# Foreign Keys
#
#  container_id             (container_id => grid_items.id)
#  deck_id                  (deck_id => grid_items.id) ON DELETE => nullify
#  grid_item_definition_id  (grid_item_definition_id => grid_item_definitions.id)
#
class GridItem < ApplicationRecord
  has_paper_trail

  ITEM_TYPES = %w[tool consumable data faction collectible rig_component material fixture gear software firmware module].freeze
  GEAR_SLOTS = %w[deck back chest head ears eyes left_wrist right_wrist hands neck waist legs feet].freeze
  VISIBLE_SLOTS = %w[head eyes chest legs feet].freeze
  RARITIES = %w[scrap ubiquitous common uncommon rare ultra_rare unicorn].freeze
  RARITY_LABELS = {
    "scrap" => "SCRAP",
    "ubiquitous" => "UBIQUITOUS",
    "common" => "COMMON",
    "uncommon" => "UNCOMMON",
    "rare" => "RARE",
    "ultra_rare" => "ULTRA-RARE",
    "unicorn" => "UNICORN"
  }.freeze
  RARITY_COLORS = {
    "scrap" => "#6b7280",
    "ubiquitous" => "#9ca3af",
    "common" => "#d0d0d0",
    "uncommon" => "#34d399",
    "rare" => "#60a5fa",
    "ultra_rare" => "#a78bfa",
    "unicorn" => "#fbbf24"
  }.freeze

  # Display fields (name, description, item_type, rarity, value, properties) are
  # denormalized snapshots copied from the definition at creation time. They are
  # NOT automatically synced when a definition is updated. To propagate definition
  # changes to existing items, run: rails data:sync_item_definitions
  belongs_to :grid_item_definition
  belongs_to :room, class_name: "GridRoom", optional: true
  belongs_to :grid_hackr, optional: true
  belongs_to :grid_mining_rig, optional: true
  belongs_to :container, class_name: "GridItem", optional: true
  belongs_to :deck_item, class_name: "GridItem", foreign_key: :deck_id, optional: true
  has_many :stored_items, class_name: "GridItem", foreign_key: :container_id, dependent: :restrict_with_error
  has_many :loaded_software, -> { where(item_type: "software") }, class_name: "GridItem", foreign_key: :deck_id, dependent: :nullify
  has_many :installed_modules, -> { where(item_type: "module") }, class_name: "GridItem", foreign_key: :deck_id, dependent: :nullify

  validates :name, presence: true
  validates :item_type, inclusion: {in: ITEM_TYPES, allow_nil: true}
  validates :rarity, inclusion: {in: RARITIES, allow_nil: true}
  validates :quantity, numericality: {greater_than: 0}, allow_nil: true
  validates :equipped_slot, inclusion: {in: GEAR_SLOTS, allow_nil: true}
  validate :single_location
  validate :equipped_slot_requirements
  validate :deck_id_requirements

  scope :in_room, ->(room) { where(room: room, grid_hackr: nil, grid_mining_rig: nil, container_id: nil) }
  scope :in_inventory, ->(hackr) { where(grid_hackr: hackr, grid_mining_rig: nil, container_id: nil, equipped_slot: nil, deck_id: nil) }
  scope :equipped_by, ->(hackr) { where(grid_hackr: hackr, grid_mining_rig: nil, container_id: nil).where.not(equipped_slot: nil) }
  scope :installed_in, ->(rig) { where(grid_mining_rig: rig, grid_hackr: nil, room: nil) }
  scope :on_floor, ->(room) { where(room: room, grid_hackr: nil, grid_mining_rig: nil, container_id: nil).where.not(item_type: "fixture") }
  scope :placed_fixtures, ->(room) { where(room: room, item_type: "fixture", grid_hackr: nil, grid_mining_rig: nil, container_id: nil) }
  scope :in_fixture, ->(fixture) { where(container: fixture) }
  scope :loaded_in_deck, ->(deck) { where(deck_id: deck.id, item_type: "software") }

  RAINBOW_COLORS = %w[#ff6b6b #fbbf24 #34d399 #22d3ee #60a5fa #a78bfa].freeze

  def rarity_color
    RARITY_COLORS[rarity] || "#9ca3af"
  end

  def rarity_label
    RARITY_LABELS[rarity] || rarity&.upcase
  end

  def unicorn?
    rarity == "unicorn"
  end

  # Rainbow-colored name for web output (CSS animation)
  def rainbow_name_html
    "<span class='rarity-unicorn'>#{ERB::Util.html_escape(name)}</span>"
  end

  # Rainbow-colored name for terminal output (static per-character colors)
  def rainbow_name_ansi
    name.chars.each_with_index.map { |char, i|
      color = RAINBOW_COLORS[i % RAINBOW_COLORS.size]
      "<span style='color: #{color};'>#{ERB::Util.html_escape(char)}</span>"
    }.join
  end

  # Returns the appropriately styled name HTML
  def styled_name_html
    unicorn? ? rainbow_name_html : ERB::Util.html_escape(name)
  end

  def rig_component?
    item_type == "rig_component"
  end

  def fixture?
    item_type == "fixture"
  end

  def storage_capacity
    properties&.dig("storage_capacity").to_i
  end

  def placed?
    fixture? && room_id.present?
  end

  def slot
    properties&.dig("slot")
  end

  def rate_multiplier
    properties&.dig("rate_multiplier")&.to_f || 1.0
  end

  def gear?
    item_type == "gear"
  end

  def software?
    item_type == "software"
  end

  def firmware?
    item_type == "firmware"
  end

  def deck_module?
    item_type == "module"
  end

  def deck_item?
    gear? && slot == "deck"
  end

  def equipped?
    equipped_slot.present?
  end

  # DECK-specific helpers (only meaningful when deck_item? is true)
  def deck_battery
    properties&.dig("battery_current").to_i
  end

  def deck_battery_max
    properties&.dig("battery_max").to_i
  end

  def deck_slot_count
    properties&.dig("slot_count").to_i
  end

  def deck_module_slot_count
    properties&.dig("module_slot_count").to_i
  end

  def deck_slots_used
    loaded_software.sum { |s| (s.properties&.dig("slot_cost") || 1).to_i }
  end

  def deck_slots_available
    [deck_slot_count - deck_slots_used, 0].max
  end

  def deck_modules_used
    installed_modules.count
  end

  def deck_modules_available
    [deck_module_slot_count - deck_modules_used, 0].max
  end

  def deck_fried?
    properties&.dig("fried_level").to_i > 0
  end

  def deck_fried_level
    properties&.dig("fried_level").to_i
  end

  def has_module?(module_slug)
    installed_modules.joins(:grid_item_definition)
      .exists?(grid_item_definitions: {slug: module_slug})
  end

  alias_method :gear_slot, :slot

  def gear_effects
    properties&.dig("effects") || {}
  end

  def required_clearance
    properties&.dig("required_clearance").to_i
  end

  private

  # An item can only be in one place: room, inventory, mining rig, or container
  def single_location
    locations = [room_id, grid_hackr_id, grid_mining_rig_id, container_id].compact.count
    if locations > 1
      errors.add(:base, "Item can only be in one location (room, inventory, mining rig, or container)")
    end
  end

  def equipped_slot_requirements
    return if equipped_slot.nil?
    errors.add(:equipped_slot, "can only be set on gear items") unless gear?
    errors.add(:equipped_slot, "requires a hackr owner") if grid_hackr_id.nil?
  end

  def deck_id_requirements
    return if deck_id.nil?
    unless software? || deck_module?
      errors.add(:deck_id, "can only be set on software or module items")
    end
  end
end
