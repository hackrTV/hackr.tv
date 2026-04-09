require "rails_helper"

RSpec.describe Grid::MiningService do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:mining_pool) { create(:grid_cache, :mining_pool) }

  def setup_hackr_with_rig(active: true)
    hackr = create(:grid_hackr, current_room: room, last_activity_at: Time.current)
    cache = create(:grid_cache, :default, grid_hackr: hackr)
    rig = create(:grid_mining_rig, grid_hackr: hackr, active: active)
    install_base_rig(rig)
    [hackr, cache, rig]
  end

  def install_base_rig(rig)
    [
      {slot: "motherboard", name: "MB", extra: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2}},
      {slot: "psu", name: "PSU"},
      {slot: "cpu", name: "CPU"},
      {slot: "gpu", name: "GPU"},
      {slot: "ram", name: "RAM"}
    ].each do |comp|
      props = {slot: comp[:slot], rate_multiplier: 1.0}.merge(comp[:extra] || {})
      GridItem.create!(
        grid_mining_rig: rig, name: comp[:name], item_type: "component",
        rarity: "common", value: 1, properties: props
      )
    end
  end

  def fund_mining_pool(amount)
    source = create(:grid_cache, :genesis)
    GridTransaction.create!(
      from_cache: source, to_cache: mining_pool, amount: amount,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  describe ".tick!" do
    before { fund_mining_pool(Grid::EconomyConfig::MINING_POOL_TOTAL) }

    it "awards CRED to active mining rigs" do
      hackr, cache, _rig = setup_hackr_with_rig(active: true)

      described_class.tick!
      expect(cache.balance).to be > 0
    end

    it "does not award CRED to inactive rigs" do
      hackr, cache, _rig = setup_hackr_with_rig(active: false)

      described_class.tick!
      expect(cache.balance).to eq(0)
    end

    it "auto-shutoffs rigs for hackrs inactive > 7 days" do
      hackr, _cache, rig = setup_hackr_with_rig(active: true)
      hackr.update_column(:last_activity_at, 8.days.ago)

      described_class.tick!
      expect(rig.reload).not_to be_active
    end

    it "does not auto-shutoff recently active hackrs" do
      _hackr, _cache, rig = setup_hackr_with_rig(active: true)

      described_class.tick!
      expect(rig.reload).to be_active
    end

    it "stops mining when halving crushes rate to zero" do
      # Drain the pool to near-zero — halving factor floors rate to 0
      drain_cache = create(:grid_cache)
      drain_amount = Grid::EconomyConfig::MINING_POOL_TOTAL - 1
      GridTransaction.create!(
        from_cache: mining_pool, to_cache: drain_cache, amount: drain_amount,
        tx_type: "transfer", tx_hash: SecureRandom.hex(32), created_at: Time.current
      )

      _hackr, cache, _rig = setup_hackr_with_rig(active: true)

      described_class.tick!
      expect(cache.balance).to eq(0) # rate floored to 0 by halving
    end

    it "caps mining reward at remaining pool balance" do
      # Drain pool to 1 CRED, but give hackr a high-multiplier rig
      drain_cache = create(:grid_cache)
      # Leave enough that halving doesn't zero the rate (drain 40% of pool)
      drain_amount = (Grid::EconomyConfig::MINING_POOL_TOTAL * 0.4).to_i
      GridTransaction.create!(
        from_cache: mining_pool, to_cache: drain_cache, amount: drain_amount,
        tx_type: "transfer", tx_hash: SecureRandom.hex(32), created_at: Time.current
      )
      remaining = mining_pool.balance

      _hackr, cache, _rig = setup_hackr_with_rig(active: true)

      described_class.tick!
      expect(cache.balance).to be > 0
      expect(cache.balance).to be <= remaining
    end

    it "cleans up stale presences" do
      channel = create(:chat_channel, slug: "live", requires_livestream: true)
      hackr = create(:grid_hackr, last_activity_at: Time.current)
      GridUplinkPresence.create!(
        grid_hackr: hackr, chat_channel: channel,
        last_seen_at: 20.minutes.ago # stale
      )

      described_class.tick!
      expect(GridUplinkPresence.count).to eq(0)
    end
  end

  describe "stream presence bonus" do
    let(:channel) { create(:chat_channel, slug: "live", requires_livestream: true) }
    let(:artist) { create(:artist) }

    before do
      fund_mining_pool(Grid::EconomyConfig::MINING_POOL_TOTAL)
    end

    it "awards bonus CRED to hackrs watching a live stream" do
      hackr, cache, rig = setup_hackr_with_rig(active: false) # rig OFF

      # Simulate live stream
      HackrStream.create!(artist: artist, is_live: true, live_url: "https://example.com", started_at: Time.current)

      # Simulate presence in #live channel
      GridUplinkPresence.create!(grid_hackr: hackr, chat_channel: channel, last_seen_at: Time.current)

      described_class.tick!
      expect(cache.balance).to be > 0 # earns even with rig off
    end

    it "does not award stream bonus when no stream is live" do
      hackr, cache, _rig = setup_hackr_with_rig(active: false)

      # No live stream
      GridUplinkPresence.create!(grid_hackr: hackr, chat_channel: channel, last_seen_at: Time.current)

      described_class.tick!
      expect(cache.balance).to eq(0)
    end
  end
end
