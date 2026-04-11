# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id                 :integer          not null, primary key
#  description        :text
#  item_type          :string
#  name               :string
#  properties         :json
#  quantity           :integer          default(1), not null
#  rarity             :string
#  value              :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  grid_hackr_id      :integer
#  grid_mining_rig_id :integer
#  room_id            :integer
#
# Indexes
#
#  index_grid_items_on_grid_mining_rig_id  (grid_mining_rig_id)
#
class GridItem < ApplicationRecord
  ITEM_TYPES = %w[tool consumable data faction collectible component].freeze
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

  belongs_to :room, class_name: "GridRoom", optional: true
  belongs_to :grid_hackr, optional: true
  belongs_to :grid_mining_rig, optional: true

  validates :name, presence: true
  validates :item_type, inclusion: {in: ITEM_TYPES, allow_nil: true}
  validates :rarity, inclusion: {in: RARITIES, allow_nil: true}
  validates :quantity, numericality: {greater_than: 0}, allow_nil: true
  validate :single_location

  scope :in_room, ->(room) { where(room: room, grid_hackr: nil, grid_mining_rig: nil) }
  scope :in_inventory, ->(hackr) { where(grid_hackr: hackr, grid_mining_rig: nil) }
  scope :installed_in, ->(rig) { where(grid_mining_rig: rig, grid_hackr: nil, room: nil) }

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

  def component?
    item_type == "component"
  end

  def slot
    properties&.dig("slot")
  end

  def rate_multiplier
    properties&.dig("rate_multiplier")&.to_f || 1.0
  end

  private

  # An item can only be in one place: room, inventory, or mining rig
  def single_location
    locations = [room_id, grid_hackr_id, grid_mining_rig_id].compact.count
    if locations > 1
      errors.add(:base, "Item can only be in one location (room, inventory, or mining rig)")
    end
  end
end
