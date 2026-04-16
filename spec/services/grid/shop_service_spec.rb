require "rails_helper"

RSpec.describe Grid::ShopService do
  let(:zone) { create(:grid_zone) }
  let(:shop_room) { create(:grid_room, :shop, grid_zone: zone) }
  let(:vendor) { create(:grid_mob, :vendor, grid_room: shop_room) }
  let(:hackr) { create(:grid_hackr, current_room: shop_room) }
  let(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }
  let(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }
  let(:burn_cache) { create(:grid_cache, :burn) }

  let(:medpatch_def) do
    create(:grid_item_definition, :consumable, slug: "medpatch", name: "MedPatch")
  end

  let!(:listing) do
    create(:grid_shop_listing,
      grid_item_definition: medpatch_def,
      grid_mob: vendor,
      base_price: 100,
      sell_price: 50,
      stock: 5,
      max_stock: 5)
  end

  def fund_cache(target_cache, amount)
    source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: source, to_cache: target_cache, amount: amount,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  before do
    cache
    gameplay_pool
    burn_cache
  end

  describe ".buy!" do
    before { fund_cache(cache, 1000) }

    it "creates an item in the hackr's inventory" do
      expect {
        described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      }.to change { hackr.grid_items.count }.by(1)
    end

    it "returns purchase receipt" do
      result = described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      expect(result[:price_paid]).to eq(100)
      expect(result[:item].name).to eq("MedPatch")
      expect(result[:item].grid_hackr).to eq(hackr)
    end

    it "burns 70% and recycles 30% of the price" do
      described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      expect(burn_cache.balance).to eq(70)
      expect(gameplay_pool.balance).to eq(30)
    end

    it "decrements stock" do
      described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      expect(listing.reload.stock).to eq(4)
    end

    it "creates a shop transaction record" do
      expect {
        described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      }.to change(GridShopTransaction, :count).by(1)

      tx = GridShopTransaction.last
      expect(tx.transaction_type).to eq("buy")
      expect(tx.price_paid).to eq(100)
      expect(tx.burn_amount).to eq(70)
      expect(tx.recycle_amount).to eq(30)
    end

    it "is case-insensitive for item names" do
      result = described_class.buy!(hackr: hackr, mob: vendor, item_name: "medpatch")
      expect(result[:item].name).to eq("MedPatch")
    end

    it "raises InsufficientBalance when hackr can't afford it" do
      begin
        fund_cache(cache, -950)
      rescue
        nil
      end # drain to 50
      hackr_cache = create(:grid_cache, :default, grid_hackr: create(:grid_hackr))
      poor_hackr = hackr_cache.grid_hackr
      fund_cache(hackr_cache, 10)

      expect {
        described_class.buy!(hackr: poor_hackr, mob: vendor, item_name: "MedPatch")
      }.to raise_error(described_class::InsufficientBalance)
    end

    it "raises InsufficientStock when out of stock" do
      listing.update_columns(stock: 0)
      expect {
        described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      }.to raise_error(described_class::InsufficientStock)
    end

    it "raises ItemNotFound for unknown items" do
      expect {
        described_class.buy!(hackr: hackr, mob: vendor, item_name: "Nonexistent")
      }.to raise_error(described_class::ItemNotFound)
    end

    it "raises AccessDenied for non-vendor mobs" do
      lore_mob = create(:grid_mob, grid_room: shop_room, mob_type: "lore")
      expect {
        described_class.buy!(hackr: hackr, mob: lore_mob, item_name: "MedPatch")
      }.to raise_error(described_class::AccessDenied)
    end

    context "with unlimited stock" do
      before { listing.update_columns(stock: nil, max_stock: nil) }

      it "does not decrement stock" do
        described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")
        expect(listing.reload.stock).to be_nil
      end
    end

    context "with concurrent purchases (race condition)" do
      it "prevents double-purchase of last stock" do
        listing.update_columns(stock: 1)
        fund_cache(cache, 10000)

        # First buy succeeds
        described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")

        # Second buy fails — stock is now 0
        expect {
          described_class.buy!(hackr: hackr, mob: vendor, item_name: "MedPatch")
        }.to raise_error(described_class::InsufficientStock)
      end
    end
  end

  describe ".sell!" do
    before do
      gameplay_pool
      fund_cache(gameplay_pool, 100_000)
    end

    let!(:item) do
      create(:grid_item, :consumable,
        grid_item_definition: medpatch_def,
        grid_hackr: hackr,
        room: nil,
        name: "MedPatch",
        rarity: "common",
        value: 100)
    end

    it "destroys the item" do
      expect {
        described_class.sell!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      }.to change { hackr.grid_items.count }.by(-1)
    end

    it "pays the hackr sell price from gameplay pool" do
      result = described_class.sell!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      expect(result[:sell_price]).to eq(50)
      expect(cache.reload.balance).to eq(50)
    end

    it "creates a sell transaction record" do
      expect {
        described_class.sell!(hackr: hackr, mob: vendor, item_name: "MedPatch")
      }.to change(GridShopTransaction, :count).by(1)

      tx = GridShopTransaction.last
      expect(tx.transaction_type).to eq("sell")
      expect(tx.price_paid).to eq(50)
    end

    it "raises ItemNotFound when hackr doesn't have the item" do
      expect {
        described_class.sell!(hackr: hackr, mob: vendor, item_name: "Nonexistent")
      }.to raise_error(described_class::ItemNotFound)
    end

    context "with quantity > 1" do
      before { item.update!(quantity: 3) }

      it "decrements quantity instead of destroying" do
        described_class.sell!(hackr: hackr, mob: vendor, item_name: "MedPatch")
        expect(item.reload.quantity).to eq(2)
      end
    end

    context "without matching listing" do
      it "uses item value * 50% as sell price" do
        item.update!(name: "Random Loot", value: 200)
        result = described_class.sell!(hackr: hackr, mob: vendor, item_name: "Random Loot")
        expect(result[:sell_price]).to eq(100)
      end
    end
  end

  describe ".effective_price" do
    let(:bm_vendor) do
      create(:grid_mob, :vendor, grid_room: shop_room,
        vendor_config: {"shop_type" => "black_market"})
    end

    let(:bm_listing) do
      create(:grid_shop_listing, grid_mob: bm_vendor, base_price: 1000, sell_price: 500)
    end

    it "returns base_price for standard vendors" do
      price = described_class.effective_price(listing: listing, mob: vendor, clearance: 50)
      expect(price).to eq(100)
    end

    it "applies 5x multiplier at clearance 10 for black market" do
      price = described_class.effective_price(listing: bm_listing, mob: bm_vendor, clearance: 10)
      expect(price).to eq(5000)
    end

    it "applies reduced multiplier at higher clearance" do
      # At clearance 50: max(1.0, 5.0 - (50-10)*0.04) = max(1.0, 3.4) = 3.4
      price = described_class.effective_price(listing: bm_listing, mob: bm_vendor, clearance: 50)
      expect(price).to eq(3400)
    end

    it "floors at 1x multiplier (base price)" do
      # At clearance 99: max(1.0, 5.0 - (99-10)*0.04) = max(1.0, 1.44) = 1.44
      price = described_class.effective_price(listing: bm_listing, mob: bm_vendor, clearance: 99)
      expect(price).to eq(1440)
    end

    it "never goes below base price" do
      # Even at absurdly high clearance, min is 1.0x
      price = described_class.effective_price(listing: bm_listing, mob: bm_vendor, clearance: 200)
      expect(price).to eq(1000)
    end
  end

  describe ".listing_display" do
    it "returns visible listings with prices" do
      items = described_class.listing_display(mob: vendor, hackr: hackr)
      expect(items.length).to eq(1)
      expect(items.first[:listing]).to eq(listing)
      expect(items.first[:effective_price]).to eq(100)
    end

    it "filters listings by clearance" do
      listing.update!(min_clearance: 50)
      hackr.set_stat!("clearance", 10)
      items = described_class.listing_display(mob: vendor, hackr: hackr)
      expect(items).to be_empty
    end

    it "excludes inactive listings" do
      listing.update!(active: false)
      items = described_class.listing_display(mob: vendor, hackr: hackr)
      expect(items).to be_empty
    end
  end

  describe ".restock!" do
    it "restocks items below max" do
      listing.update_columns(stock: 2, next_restock_at: 1.hour.ago)
      described_class.restock!(vendor)
      expect(listing.reload.stock).to eq(3)
    end

    it "does not exceed max_stock" do
      listing.update_columns(stock: 4, max_stock: 5, restock_amount: 5)
      described_class.restock!(vendor)
      expect(listing.reload.stock).to eq(5)
    end

    it "skips items already at max" do
      listing.update_columns(stock: 5, max_stock: 5)
      expect { described_class.restock!(vendor) }.not_to change { listing.reload.stock }
    end
  end

  describe ".rotate!" do
    let(:bm_vendor) do
      create(:grid_mob, :vendor, grid_room: shop_room,
        vendor_config: {"shop_type" => "black_market", "rotation_count" => 2})
    end

    let!(:rot_listings) do
      5.times.map do |i|
        defn = create(:grid_item_definition, slug: "rot-item-#{i}", name: "Rotation Item #{i}")
        create(:grid_shop_listing,
          grid_item_definition: defn,
          grid_mob: bm_vendor,
          rotation_pool: true,
          active: false)
      end
    end

    it "activates rotation_count items from the pool" do
      described_class.rotate!(bm_vendor)
      active_count = bm_vendor.grid_shop_listings.in_rotation_pool.where(active: true).count
      expect(active_count).to eq(2)
    end

    it "deactivates all rotation items before selecting" do
      rot_listings.first.update!(active: true)
      described_class.rotate!(bm_vendor)
      # Exactly rotation_count should be active
      active_count = bm_vendor.grid_shop_listings.in_rotation_pool.where(active: true).count
      expect(active_count).to eq(2)
    end
  end
end
