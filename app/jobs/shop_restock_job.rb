# frozen_string_literal: true

class ShopRestockJob < ApplicationJob
  queue_as :default

  def perform
    GridShopListing
      .where(active: true)
      .where.not(max_stock: nil)
      .where("next_restock_at IS NULL OR next_restock_at <= ?", Time.current)
      .find_each do |listing|
        next if listing.stock.present? && listing.stock >= listing.max_stock

        new_stock = [(listing.stock || 0) + listing.restock_amount, listing.max_stock].min
        listing.update_columns(
          stock: new_stock,
          next_restock_at: Time.current + listing.restock_interval_hours.hours
        )
      end
  end
end
