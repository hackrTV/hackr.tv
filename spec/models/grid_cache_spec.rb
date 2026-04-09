# == Schema Information
#
# Table name: grid_caches
# Database name: primary
#
#  id            :integer          not null, primary key
#  address       :string           not null
#  archived_at   :datetime
#  is_default    :boolean          default(FALSE), not null
#  nickname      :string
#  status        :string           default("active"), not null
#  system_type   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer
#
# Indexes
#
#  index_grid_caches_on_address         (address) UNIQUE
#  index_grid_caches_on_grid_hackr_id   (grid_hackr_id)
#  index_grid_caches_on_hackr_nickname  (grid_hackr_id,nickname) UNIQUE WHERE nickname IS NOT NULL
#  index_grid_caches_on_system_type     (system_type)
#
require "rails_helper"

RSpec.describe GridCache, type: :model do
  describe "validations" do
    it "requires an address" do
      cache = build(:grid_cache, address: nil)
      expect(cache).not_to be_valid
    end

    it "requires a unique address" do
      create(:grid_cache, address: "CACHE-AAAA-BBBB")
      duplicate = build(:grid_cache, address: "CACHE-AAAA-BBBB")
      expect(duplicate).not_to be_valid
    end

    it "requires a valid status" do
      cache = build(:grid_cache, status: "invalid")
      expect(cache).not_to be_valid
    end

    it "validates nickname format" do
      cache = build(:grid_cache, nickname: "has spaces")
      expect(cache).not_to be_valid
    end

    it "validates nickname max length" do
      cache = build(:grid_cache, nickname: "a" * 21)
      expect(cache).not_to be_valid
    end

    it "rejects reserved nicknames" do
      cache = build(:grid_cache, nickname: "send")
      expect(cache).not_to be_valid
    end

    it "accepts valid nicknames" do
      hackr = create(:grid_hackr)
      cache = build(:grid_cache, grid_hackr: hackr, nickname: "my-savings")
      expect(cache).to be_valid
    end
  end

  describe ".generate_address" do
    it "returns a CACHE-XXXX-XXXX formatted address" do
      address = described_class.generate_address
      expect(address).to match(/\ACACHE-[A-F0-9]{4}-[A-F0-9]{4}\z/)
    end

    it "generates unique addresses" do
      addresses = 10.times.map { described_class.generate_address }
      expect(addresses.uniq.size).to eq(10)
    end
  end

  describe "#balance" do
    let(:cache) { create(:grid_cache) }
    let(:other) { create(:grid_cache) }

    it "returns 0 with no transactions" do
      expect(cache.balance).to eq(0)
    end

    it "computes balance from ledger" do
      # Simulate incoming
      GridTransaction.create!(
        from_cache: other, to_cache: cache, amount: 100,
        tx_type: "transfer", tx_hash: "hash1", created_at: Time.current
      )
      # Simulate outgoing
      GridTransaction.create!(
        from_cache: cache, to_cache: other, amount: 30,
        tx_type: "transfer", tx_hash: "hash2", previous_tx_hash: "hash1", created_at: Time.current
      )

      expect(cache.balance).to eq(70)
    end
  end

  describe "#abandon!" do
    it "sets status to abandoned with timestamp" do
      cache = create(:grid_cache, status: "active")
      cache.abandon!
      expect(cache.status).to eq("abandoned")
      expect(cache.archived_at).to be_present
    end
  end

  describe "system cache finders" do
    before do
      create(:grid_cache, :mining_pool)
      create(:grid_cache, :gameplay_pool)
      create(:grid_cache, :burn)
      create(:grid_cache, :redemption)
      create(:grid_cache, :genesis)
    end

    it "finds each system cache by type" do
      expect(described_class.mining_pool.system_type).to eq("mining_pool")
      expect(described_class.gameplay_pool.system_type).to eq("gameplay_pool")
      expect(described_class.burn.system_type).to eq("burn")
      expect(described_class.redemption.system_type).to eq("redemption")
      expect(described_class.genesis.system_type).to eq("genesis")
    end
  end
end
