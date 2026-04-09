require "rails_helper"

RSpec.describe GridTransaction, type: :model do
  let(:from_cache) { create(:grid_cache) }
  let(:to_cache) { create(:grid_cache) }

  describe "validations" do
    it "requires a positive amount" do
      tx = build_tx(amount: 0)
      expect(tx).not_to be_valid
    end

    it "requires a valid tx_type" do
      tx = build_tx(tx_type: "invalid")
      expect(tx).not_to be_valid
    end

    it "requires a unique tx_hash" do
      create_tx(tx_hash: "duplicate_hash")
      tx = build_tx(tx_hash: "duplicate_hash")
      expect(tx).not_to be_valid
    end
  end

  describe "immutability" do
    it "raises on update" do
      tx = create_tx
      expect { tx.update!(memo: "changed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises on destroy" do
      tx = create_tx
      expect { tx.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe "#compute_hash" do
    it "returns a SHA-256 hex digest" do
      tx = build_tx(created_at: Time.current)
      hash = tx.compute_hash
      expect(hash).to match(/\A[a-f0-9]{64}\z/)
    end

    it "produces different hashes for different data" do
      now = Time.current
      tx1 = build_tx(amount: 10, created_at: now)
      tx2 = build_tx(amount: 20, created_at: now)
      expect(tx1.compute_hash).not_to eq(tx2.compute_hash)
    end
  end

  describe "#short_hash" do
    it "returns the first 12 characters" do
      tx = create_tx(tx_hash: "abcdef1234567890")
      expect(tx.short_hash).to eq("abcdef123456")
    end
  end

  describe "scopes" do
    it ".recent orders by created_at desc" do
      old = create_tx(created_at: 1.hour.ago, tx_hash: "old")
      new_tx = create_tx(created_at: Time.current, tx_hash: "new")
      expect(described_class.recent.first).to eq(new_tx)
    end

    it ".for_cache returns transactions involving a cache" do
      other = create(:grid_cache)
      create_tx(from_cache: from_cache, to_cache: to_cache, tx_hash: "relevant")
      create_tx(from_cache: other, to_cache: create(:grid_cache), tx_hash: "irrelevant")

      results = described_class.for_cache(from_cache)
      expect(results.pluck(:tx_hash)).to include("relevant")
      expect(results.pluck(:tx_hash)).not_to include("irrelevant")
    end
  end

  private

  def build_tx(overrides = {})
    attrs = {
      from_cache: from_cache, to_cache: to_cache, amount: 10,
      tx_type: "transfer", tx_hash: SecureRandom.hex(32),
      created_at: Time.current
    }.merge(overrides)
    described_class.new(attrs)
  end

  def create_tx(overrides = {})
    tx = build_tx(overrides)
    tx.save!
    tx
  end
end
