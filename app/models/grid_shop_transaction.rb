# frozen_string_literal: true

class GridShopTransaction < ApplicationRecord
  TRANSACTION_TYPES = %w[buy sell].freeze

  belongs_to :grid_hackr
  belongs_to :grid_shop_listing, optional: true
  belongs_to :grid_mob

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
