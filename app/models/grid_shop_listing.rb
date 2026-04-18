# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_shop_listings
# Database name: primary
#
#  id                      :integer          not null, primary key
#  active                  :boolean          default(TRUE), not null
#  base_price              :integer          not null
#  max_stock               :integer
#  min_clearance           :integer          default(0), not null
#  next_restock_at         :datetime
#  restock_amount          :integer          default(1), not null
#  restock_interval_hours  :integer          default(24), not null
#  rotation_pool           :boolean          default(FALSE), not null
#  sell_price              :integer          not null
#  stock                   :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  grid_item_definition_id :integer          not null
#  grid_mob_id             :integer          not null
#
# Indexes
#
#  index_grid_shop_listings_on_grid_item_definition_id  (grid_item_definition_id)
#  index_grid_shop_listings_on_grid_mob_id              (grid_mob_id)
#  index_grid_shop_listings_on_grid_mob_id_and_active   (grid_mob_id,active)
#  index_grid_shop_listings_on_next_restock_at          (next_restock_at)
#
# Foreign Keys
#
#  grid_item_definition_id  (grid_item_definition_id => grid_item_definitions.id)
#  grid_mob_id              (grid_mob_id => grid_mobs.id)
#
class GridShopListing < ApplicationRecord
  has_paper_trail

  belongs_to :grid_mob
  belongs_to :grid_item_definition
  has_many :grid_shop_transactions, dependent: :nullify

  delegate :name, :description, :item_type, :rarity, :properties,
    :rarity_color, :rarity_label,
    to: :grid_item_definition

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

  private

  def compute_sell_price
    self.sell_price = (base_price / 2.0).ceil
  end
end
