require "rails_helper"

RSpec.describe Grid::AchievementAwarder do
  let(:hackr) { create(:grid_hackr) }
  let!(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }
  let!(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }

  before do
    # Fund the gameplay pool so mint_gameplay! can succeed
    genesis_source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: genesis_source, to_cache: gameplay_pool, amount: 1_000_000,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  describe "#award!" do
    let(:achievement) do
      create(:grid_achievement,
        slug: "test-cred",
        xp_reward: 25,
        cred_reward: 10)
    end

    it "creates the join row" do
      expect { described_class.new(hackr, achievement).award! }
        .to change { hackr.grid_hackr_achievements.count }.by(1)
    end

    it "grants XP" do
      expect {
        described_class.new(hackr, achievement).award!
        hackr.reload
      }.to change { hackr.stat("xp") }.from(0).to(25)
    end

    it "mints CRED from the gameplay pool to the hackr's default cache" do
      expect { described_class.new(hackr, achievement).award! }
        .to change { cache.reload.balance }.by(10)
    end

    it "skips the CRED mint (but still awards XP + join row) when cache is inactive" do
      cache.update!(status: "abandoned")

      expect {
        described_class.new(hackr, achievement).award!
        hackr.reload
      }.to change { hackr.grid_hackr_achievements.count }.by(1)
        .and change { hackr.stat("xp") }.by(25)

      expect(cache.reload.balance).to eq(0)
    end

    it "rolls back XP + join row when mint_gameplay! raises mid-transaction" do
      allow(Grid::TransactionService).to receive(:mint_gameplay!)
        .and_raise(Grid::TransactionService::InsufficientBalance, "pool empty")

      expect {
        described_class.new(hackr, achievement).award!
      }.to raise_error(Grid::TransactionService::InsufficientBalance)

      hackr.reload
      expect(hackr.grid_hackr_achievements.count).to eq(0)
      expect(hackr.stat("xp")).to eq(0)
    end

    it "returns a notification string when newly awarded" do
      result = described_class.new(hackr, achievement).award!
      expect(result).to include("ACHIEVEMENT UNLOCKED")
      expect(result).to include(achievement.name)
      expect(result).to include("+25 XP")
      expect(result).to include("+10 CRED")
    end

    it "returns nil on duplicate award (race guard)" do
      described_class.new(hackr, achievement).award!
      result = described_class.new(hackr, achievement).award!
      expect(result).to be_nil
    end

    it "broadcasts to the per-hackr AchievementChannel stream" do
      expect(ActionCable.server).to receive(:broadcast).with(
        "achievement_channel_#{hackr.id}",
        hash_including(type: "achievement_unlocked")
      )
      described_class.new(hackr, achievement).award!
    end

    it "skips CRED mint when cred_reward is zero" do
      no_cred = create(:grid_achievement, slug: "no-cred", xp_reward: 10, cred_reward: 0)

      expect(Grid::TransactionService).not_to receive(:mint_gameplay!)
      described_class.new(hackr, no_cred).award!
    end
  end

  describe "#award! — awarder survives broadcast failure" do
    let(:achievement) { create(:grid_achievement, xp_reward: 10) }

    it "does not raise if ActionCable broadcast throws" do
      allow(ActionCable.server).to receive(:broadcast).and_raise(StandardError, "oops")

      expect {
        described_class.new(hackr, achievement).award!
      }.not_to raise_error
      expect(hackr.grid_hackr_achievements.count).to eq(1)
    end
  end
end
