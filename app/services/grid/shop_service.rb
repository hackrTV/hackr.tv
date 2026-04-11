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

      mob.grid_shop_listings.where(active: true).order(:rarity, :name).map do |listing|
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

    # Buy an item from a vendor
    def self.buy!(hackr:, mob:, item_name:)
      raise AccessDenied, "This vendor doesn't sell anything" unless mob.vendor?

      clearance = hackr.stat("clearance")
      listing = mob.grid_shop_listings.where(active: true)
        .find_by("LOWER(name) = ?", item_name.downcase)

      raise ItemNotFound, "This vendor doesn't sell '#{item_name}'" unless listing
      raise AccessDenied, "CLEARANCE #{listing.min_clearance}+ required" if clearance < listing.min_clearance
      raise InsufficientStock, "'#{listing.name}' is out of stock" if listing.out_of_stock?

      price = effective_price(listing: listing, mob: mob, clearance: clearance)
      cache = hackr.default_cache
      raise InsufficientBalance, "Insufficient CRED (need #{price}, have #{cache&.balance || 0})" unless cache && cache.balance >= price

      item = nil

      ActiveRecord::Base.transaction do
        # Optimistic stock decrement — prevents race condition
        unless listing.unlimited_stock?
          updated = GridShopListing.where(id: listing.id).where("stock > 0")
            .update_all("stock = stock - 1")
          raise InsufficientStock, "'#{listing.name}' is out of stock" if updated == 0
        end

        # Split CRED: burn 70%, recycle 30% to gameplay pool
        split_purchase!(hackr_cache: cache, amount: price, item_name: listing.name)

        # Create item in hackr's inventory
        item = GridItem.create!(
          grid_hackr: hackr,
          name: listing.name,
          description: listing.description,
          item_type: listing.item_type,
          rarity: listing.rarity,
          value: listing.base_price,
          quantity: 1,
          properties: listing.properties
        )

        # Record the shop transaction
        GridShopTransaction.create!(
          grid_hackr: hackr,
          grid_shop_listing: listing,
          grid_mob: mob,
          transaction_type: "buy",
          quantity: 1,
          price_paid: price,
          burn_amount: burn_amount(price),
          recycle_amount: price - burn_amount(price),
          created_at: Time.current
        )
      end

      {listing: listing, item: item, price_paid: price, new_balance: cache.reload.balance}
    end

    # Sell an item to a vendor
    def self.sell!(hackr:, mob:, item_name:)
      raise AccessDenied, "This vendor doesn't buy anything" unless mob.vendor?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      raise ItemNotFound, "You don't have '#{item_name}'" unless item

      # Find matching listing for sell price, or use item.value * SELL_PRICE_RATIO
      listing = mob.grid_shop_listings.find_by("LOWER(name) = ?", item_name.downcase)
      sell_price = if listing
        listing.sell_price
      else
        (item.value * EconomyConfig::SELL_PRICE_RATIO).ceil
      end
      sell_price = [sell_price, 1].max # minimum 1 CRED

      cache = hackr.default_cache
      raise AccessDenied, "You need a cache to receive CRED" unless cache

      item_name_saved = item.name

      ActiveRecord::Base.transaction do
        # Pay the hackr from gameplay pool
        Grid::TransactionService.mint_gameplay!(
          to_cache: cache,
          amount: sell_price,
          memo: "Sell: #{item.name}"
        )

        # Remove the item
        if item.quantity > 1
          item.update!(quantity: item.quantity - 1)
        else
          item.destroy!
        end

        # Record the shop transaction
        GridShopTransaction.create!(
          grid_hackr: hackr,
          grid_shop_listing: listing,
          grid_mob: mob,
          transaction_type: "sell",
          quantity: 1,
          price_paid: sell_price,
          burn_amount: 0,
          recycle_amount: 0,
          created_at: Time.current
        )
      end

      {item_name: item_name_saved, sell_price: sell_price, new_balance: cache.reload.balance}
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
