# frozen_string_literal: true

module Grid
  class ShopService
    class InsufficientBalance < StandardError; end
    class InsufficientStock < StandardError; end
    class AccessDenied < StandardError; end
    class ItemNotFound < StandardError; end

    # Returns visible listings with effective prices for a given hackr
    def self.listing_display(mob:, hackr:)
      clearance = hackr.stat("clearance")
      cache = hackr.default_cache

      mob.grid_shop_listings.includes(:grid_item_definition)
        .joins(:grid_item_definition)
        .where(active: true)
        .order("grid_item_definitions.rarity, grid_item_definitions.name")
        .map do |listing|
          next if listing.min_clearance > clearance

          price = effective_price(listing: listing, mob: mob, clearance: clearance)
          balance = cache&.balance || 0

          {
            listing: listing,
            effective_price: price,
            affordable: balance >= price,
            out_of_stock: listing.out_of_stock?
          }
      end.compact
    end

    # Buy item(s) from a vendor. Quantity defaults to 1.
    def self.buy!(hackr:, mob:, item_name:, quantity: 1)
      raise AccessDenied, "This vendor doesn't sell anything" unless mob.vendor?

      clearance = hackr.stat("clearance")
      scope = mob.grid_shop_listings.joins(:grid_item_definition).where(active: true)
      listing = Grid::NameResolver.resolve(scope, item_name, column: "grid_item_definitions.name")

      raise ItemNotFound, "This vendor doesn't sell '#{item_name}'" unless listing
      raise AccessDenied, "CLEARANCE #{listing.min_clearance}+ required" if clearance < listing.min_clearance

      unit_price = effective_price(listing: listing, mob: mob, clearance: clearance)
      total_price = unit_price * quantity
      cache = hackr.default_cache
      raise InsufficientBalance, "Insufficient CRED (need #{total_price}, have #{cache&.balance || 0})" unless cache && cache.balance >= total_price

      # Check stock availability for full quantity
      unless listing.unlimited_stock?
        raise InsufficientStock, "'#{listing.name}' is out of stock" if listing.out_of_stock?
        raise InsufficientStock, "Only #{listing.stock} '#{listing.name}' in stock (requested #{quantity})" if listing.stock < quantity
      end

      item = nil

      ActiveRecord::Base.transaction do
        # Optimistic stock decrement — prevents race condition
        unless listing.unlimited_stock?
          updated = GridShopListing.where(id: listing.id).where("stock >= ?", quantity)
            .update_all(["stock = stock - ?", quantity])
          raise InsufficientStock, "'#{listing.name}' is out of stock" if updated == 0
        end

        # Grant items — fail fast on inventory full before touching CRED
        item = Grid::Inventory.grant_item!(
          hackr: hackr,
          definition: listing.grid_item_definition,
          quantity: quantity
        )

        # Split CRED: burn 70%, recycle 30% to gameplay pool
        split_purchase!(hackr_cache: cache, amount: total_price, item_name: listing.name)

        # Record the shop transaction
        GridShopTransaction.create!(
          grid_hackr: hackr,
          grid_shop_listing: listing,
          grid_mob: mob,
          transaction_type: "buy",
          quantity: quantity,
          price_paid: total_price,
          burn_amount: burn_amount(total_price),
          recycle_amount: total_price - burn_amount(total_price),
          created_at: Time.current
        )
      end

      {listing: listing, item: item, price_paid: total_price, quantity: quantity, new_balance: cache.reload.balance}
    end

    # Sell item(s) to a vendor. Quantity defaults to 1; :all sells entire stack.
    def self.sell!(hackr:, mob:, item_name:, quantity: 1)
      raise AccessDenied, "This vendor doesn't buy anything" unless mob.vendor?

      item = Grid::NameResolver.resolve(hackr.grid_items.in_inventory(hackr), item_name)
      raise ItemNotFound, "You don't have '#{item_name}'" unless item

      # Find matching listing for sell price, or use item.value * SELL_PRICE_RATIO
      listing = mob.grid_shop_listings.joins(:grid_item_definition)
        .where("LOWER(grid_item_definitions.name) = ?", item.name.downcase)
        .first
      unit_sell_price = if listing
        listing.sell_price
      else
        (item.value * EconomyConfig::SELL_PRICE_RATIO).ceil
      end
      unit_sell_price = [unit_sell_price, 1].max # minimum 1 CRED

      cache = hackr.default_cache
      raise AccessDenied, "You need a cache to receive CRED" unless cache

      item_name_saved = item.name
      qty = nil
      total_sell_price = nil

      ActiveRecord::Base.transaction do
        item.lock!
        qty = (quantity == :all) ? item.quantity : quantity.to_i
        raise InsufficientStock, "You only have #{item.quantity} (requested #{qty})." if qty > item.quantity
        total_sell_price = unit_sell_price * qty

        # Pay the hackr from gameplay pool
        Grid::TransactionService.mint_gameplay!(
          to_cache: cache,
          amount: total_sell_price,
          memo: "Sell: #{item.name} ×#{qty}"
        )

        # Remove the items
        remaining = item.quantity - qty
        if remaining > 0
          item.update!(quantity: remaining)
        else
          item.destroy!
        end

        # Record the shop transaction
        GridShopTransaction.create!(
          grid_hackr: hackr,
          grid_shop_listing: listing,
          grid_mob: mob,
          transaction_type: "sell",
          quantity: qty,
          price_paid: total_sell_price,
          burn_amount: 0,
          recycle_amount: 0,
          created_at: Time.current
        )
      end

      {item_name: item_name_saved, sell_price: total_sell_price, quantity: qty, new_balance: cache.reload.balance}
    end

    # Compute effective price for a listing
    def self.effective_price(listing:, mob:, clearance: 0)
      if mob.black_market?
        multiplier = [1.0, EconomyConfig::BLACK_MARKET_BASE_MULTIPLIER -
          (clearance - EconomyConfig::BLACK_MARKET_MIN_CLEARANCE) *
            EconomyConfig::BLACK_MARKET_CLEARANCE_REDUCTION].max
        (listing.base_price * multiplier).ceil
      else
        listing.base_price
      end
    end

    # Restock a vendor's limited-stock listings
    def self.restock!(mob)
      mob.grid_shop_listings.where(active: true).where.not(max_stock: nil).find_each do |listing|
        next if listing.stock >= listing.max_stock

        new_stock = [listing.stock + listing.restock_amount, listing.max_stock].min
        listing.update_columns(
          stock: new_stock,
          next_restock_at: Time.current + listing.restock_interval_hours.hours
        )
      end
    end

    # Rotate a vendor's rotation pool listings
    def self.rotate!(mob)
      pool = mob.grid_shop_listings.in_rotation_pool
      return if pool.empty?
      return if mob.rotation_count < 1

      ActiveRecord::Base.transaction do
        pool.update_all(active: false)
        selected_ids = pool.pluck(:id).sample(mob.rotation_count)
        GridShopListing.where(id: selected_ids).update_all(active: true)
      end
    end

    def self.burn_amount(price)
      (price * EconomyConfig::SHOP_BURN_RATIO).floor
    end
    private_class_method :burn_amount

    def self.split_purchase!(hackr_cache:, amount:, item_name:)
      burn_amt = burn_amount(amount)
      recycle_amt = amount - burn_amt

      if burn_amt > 0
        Grid::TransactionService.burn!(
          from_cache: hackr_cache,
          amount: burn_amt,
          memo: "Shop purchase: #{item_name}"
        )
      end

      if recycle_amt > 0
        Grid::TransactionService.recycle!(
          from_cache: hackr_cache,
          amount: recycle_amt,
          memo: "Shop recycle: #{item_name}"
        )
      end
    end
    private_class_method :split_purchase!
  end
end
