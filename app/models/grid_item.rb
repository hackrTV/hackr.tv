# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id            :integer          not null, primary key
#  description   :text
#  item_type     :string
#  name          :string
#  properties    :json
#  quantity      :integer          default(1), not null
#  rarity        :string
#  value         :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer
#  room_id       :integer
#
class GridItem < ApplicationRecord
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

  validates :name, presence: true
  validates :item_type, inclusion: {in: %w[tool consumable data faction collectible], allow_nil: true}
  validates :rarity, inclusion: {in: RARITIES, allow_nil: true}
  validates :quantity, numericality: {greater_than: 0}, allow_nil: true

  scope :in_room, ->(room) { where(room: room, grid_hackr: nil) }
  scope :in_inventory, ->(hackr) { where(grid_hackr: hackr) }

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
end
