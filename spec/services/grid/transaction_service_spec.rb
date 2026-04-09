require "rails_helper"

RSpec.describe Grid::TransactionService do
  let(:hackr_a) { create(:grid_hackr) }
  let(:hackr_b) { create(:grid_hackr) }
  let(:cache_a) { create(:grid_cache, :default, grid_hackr: hackr_a) }
  let(:cache_b) { create(:grid_cache, :default, grid_hackr: hackr_b) }
  let(:mining_pool) { create(:grid_cache, :mining_pool) }
  let(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }
  let(:burn_cache) { create(:grid_cache, :burn) }
  let(:redemption_cache) { create(:grid_cache, :redemption) }

  def fund_cache(cache, amount)
    source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: source, to_cache: cache, amount: amount,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  describe ".transfer!" do
    before { fund_cache(cache_a, 100) }

    it "creates a ledger transaction" do
      expect {
        described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 50)
      }.to change(GridTransaction, :count).by(1)
    end

    it "debits the sender and credits the receiver" do
      described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 50)
      expect(cache_a.balance).to eq(50)
      expect(cache_b.balance).to eq(50)
    end

    it "sets correct tx_type" do
      tx = described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 50)
      expect(tx.tx_type).to eq("transfer")
    end

    it "computes a valid hash" do
      tx = described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 50)
      expect(tx.tx_hash).to match(/\A[a-f0-9]{64}\z/)
    end

    it "chains to the previous transaction" do
      previous = GridTransaction.recent.first
      tx = described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 50)
      expect(tx.previous_tx_hash).to eq(previous.tx_hash)
    end

    it "raises InsufficientBalance when overdrawing" do
      expect {
        described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 200)
      }.to raise_error(described_class::InsufficientBalance)
    end

    it "raises InvalidTransfer for same cache" do
      expect {
        described_class.transfer!(from_cache: cache_a, to_cache: cache_a, amount: 10)
      }.to raise_error(described_class::InvalidTransfer, /same cache/i)
    end

    it "raises InvalidTransfer for zero amount" do
      expect {
        described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 0)
      }.to raise_error(described_class::InvalidTransfer)
    end

    it "raises InvalidTransfer for abandoned source cache" do
      cache_a.abandon!
      expect {
        described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 10)
      }.to raise_error(described_class::InvalidTransfer, /not active/i)
    end
  end

  describe ".mint_mining!" do
    before { fund_cache(mining_pool, 1000) }

    it "transfers from mining pool" do
      tx = described_class.mint_mining!(to_cache: cache_a, amount: 10)
      expect(tx.from_cache).to eq(mining_pool)
      expect(tx.tx_type).to eq("mining_reward")
    end

    it "raises when pool is depleted" do
      expect {
        described_class.mint_mining!(to_cache: cache_a, amount: 2000)
      }.to raise_error(described_class::InsufficientBalance)
    end
  end

  describe ".redeem!" do
    before do
      redemption_cache # ensure exists
      fund_cache(cache_a, 100)
    end

    it "transfers to redemption sink" do
      tx = described_class.redeem!(from_cache: cache_a, amount: 25, memo: "TTS")
      expect(tx.to_cache).to eq(redemption_cache)
      expect(tx.tx_type).to eq("redemption")
      expect(tx.memo).to eq("TTS")
    end
  end

  describe "concurrency safety" do
    before { fund_cache(cache_a, 100) }

    it "prevents double-spend via mutex serialization" do
      # Two threads trying to spend the same 100 CRED
      results = []
      threads = 2.times.map do
        Thread.new do
          described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 100)
          results << :success
        rescue described_class::InsufficientBalance
          results << :insufficient
        end
      end
      threads.each(&:join)

      expect(results.count(:success)).to eq(1)
      expect(results.count(:insufficient)).to eq(1)
      expect(cache_a.balance).to eq(0)
      expect(cache_b.balance).to eq(100)
    end

    it "maintains hash chain integrity under concurrent writes" do
      fund_cache(cache_a, 1000)

      threads = 5.times.map do |i|
        Thread.new do
          described_class.transfer!(from_cache: cache_a, to_cache: cache_b, amount: 1, memo: "tx-#{i}")
        end
      end
      threads.each(&:join)

      # Verify the chain among TransactionService-created transactions only
      # (fund_cache creates raw records that bypass the chain)
      service_txs = GridTransaction.where(tx_type: "transfer").order(:created_at, :id).to_a
      service_txs.each_cons(2) do |prev_tx, curr_tx|
        expect(curr_tx.previous_tx_hash).to eq(prev_tx.tx_hash),
          "Chain broken: tx #{curr_tx.id} has previous_tx_hash=#{curr_tx.previous_tx_hash} but expected #{prev_tx.tx_hash}"
      end
      expect(service_txs.size).to eq(5)
    end
  end
end
