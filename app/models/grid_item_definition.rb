# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_item_definitions
# Database name: primary
#
#  id          :integer          not null, primary key
#  description :text
#  item_type   :string           not null
#  name        :string           not null
#  properties  :json             not null
#  rarity      :string           not null
#  slug        :string           not null
#  value       :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_grid_item_definitions_on_item_type  (item_type)
#  index_grid_item_definitions_on_slug       (slug) UNIQUE
#
class GridItemDefinition < ApplicationRecord
  has_paper_trail

  has_many :grid_items, dependent: :restrict_with_error
  has_many :grid_shop_listings, dependent: :restrict_with_error
  has_many :salvage_yields, class_name: "GridSalvageYield",
    foreign_key: :source_definition_id, dependent: :destroy
  has_many :output_definitions, through: :salvage_yields, source: :output_definition

  accepts_nested_attributes_for :salvage_yields,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs["output_definition_id"].blank? }

  validates :slug, presence: true, uniqueness: true,
    format: {with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens"}
  validates :name, presence: true
  validates :item_type, presence: true, inclusion: {in: GridItem::ITEM_TYPES}
  validates :rarity, presence: true, inclusion: {in: GridItem::RARITIES}
  validates :value, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :ordered, -> { order(:item_type, :name) }
  scope :by_item_type, ->(t) { where(item_type: t) }

  def to_param
    slug
  end

  def rarity_color
    GridItem::RARITY_COLORS[rarity] || "#9ca3af"
  end

  def rarity_label
    GridItem::RARITY_LABELS[rarity] || rarity&.upcase
  end

  # Build a GridItem attribute hash from this definition.
  # Callers merge instance-specific fields (grid_hackr, room, quantity, etc.)
  def item_attributes
    {
      grid_item_definition: self,
      name: name,
      description: description,
      item_type: item_type,
      rarity: rarity,
      value: value,
      properties: properties&.deep_dup || {}
    }
  end
end
