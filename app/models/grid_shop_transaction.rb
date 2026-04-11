# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_shop_transactions
# Database name: primary
#
#  id                   :integer          not null, primary key
#  burn_amount          :integer          default(0), not null
#  price_paid           :integer          not null
#  quantity             :integer          default(1), not null
#  recycle_amount       :integer          default(0), not null
#  transaction_type     :string           not null
#  created_at           :datetime         not null
#  grid_hackr_id        :integer
#  grid_mob_id          :integer
#  grid_shop_listing_id :integer
#
# Indexes
#
#  index_grid_shop_transactions_on_grid_hackr_id                 (grid_hackr_id)
#  index_grid_shop_transactions_on_grid_hackr_id_and_created_at  (grid_hackr_id,created_at)
#  index_grid_shop_transactions_on_grid_mob_id                   (grid_mob_id)
#  index_grid_shop_transactions_on_grid_shop_listing_id          (grid_shop_listing_id)
#
class GridShopTransaction < ApplicationRecord
  TRANSACTION_TYPES = %w[buy sell].freeze

  belongs_to :grid_hackr, optional: true
  belongs_to :grid_shop_listing, optional: true
  belongs_to :grid_mob, optional: true

  validates :transaction_type, inclusion: {in: TRANSACTION_TYPES}
  validates :quantity, numericality: {only_integer: true, greater_than: 0}
  validates :price_paid, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :recent, -> { order(created_at: :desc) }
  scope :purchases, -> { where(transaction_type: "buy") }
  scope :sales, -> { where(transaction_type: "sell") }

  # Immutable: prevent updates and deletes
  before_update { raise ActiveRecord::ReadOnlyRecord, "GridShopTransaction records are immutable" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "GridShopTransaction records cannot be deleted" }
end
