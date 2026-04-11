# frozen_string_literal: true

class GridShopListing < ApplicationRecord
  belongs_to :grid_mob
  has_many :grid_shop_transactions, dependent: :nullify

  validates :name, presence: true
  validates :item_type, inclusion: {in: GridItem::ITEM_TYPES}, allow_nil: true
  validates :rarity, inclusion: {in: GridItem::RARITIES}, allow_nil: true
  validates :base_price, numericality: {only_integer: true, greater_than: 0}
  validates :sell_price, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :stock, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validates :max_stock, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
  validates :restock_amount, numericality: {only_integer: true, greater_than: 0}
  validates :restock_interval_hours, numericality: {only_integer: true, greater_than: 0}
  validates :min_clearance, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :available, -> { where(active: true).where("stock IS NULL OR stock > 0") }
  scope :in_rotation_pool, -> { where(rotation_pool: true) }

  before_validation :compute_sell_price, if: -> { sell_price.blank? && base_price.present? }

  def unlimited_stock?
    stock.nil?
  end

  def out_of_stock?
    !unlimited_stock? && stock <= 0
  end

  def in_stock?
    unlimited_stock? || stock > 0
  end

  def rarity_color
    GridItem::RARITY_COLORS[rarity] || "#9ca3af"
  end

  def rarity_label
    GridItem::RARITY_LABELS[rarity] || rarity&.upcase
  end

  private

  def compute_sell_price
    self.sell_price = (base_price / 2.0).ceil
  end
end
