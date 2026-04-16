require "rails_helper"

RSpec.describe Grid::AchievementChecker, "mission-related triggers" do
  let(:hackr) { create(:grid_hackr) }
  let(:checker) { described_class.new(hackr) }
  let!(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }
  let!(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }

  before do
    genesis_source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: genesis_source, to_cache: gameplay_pool, amount: 1_000_000,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  describe "purchase_item" do
    it "is in the trigger types allowlist" do
      expect(GridAchievement::TRIGGER_TYPES).to include("purchase_item")
    end

    it "matches when target item_name equals context item_name (case-insensitive)" do
      ach = create(:grid_achievement,
        slug: "first-buy", trigger_type: "purchase_item",
        trigger_data: {"item_name" => "Signal Fragment"},
        xp_reward: 5)
      notifs = checker.check(:purchase_item, item_name: "signal fragment")
      expect(notifs.size).to eq(1)
      expect(hackr.grid_hackr_achievements.pluck(:grid_achievement_id)).to include(ach.id)
    end

    it "matches with blank target (unlocks on any purchase)" do
      create(:grid_achievement,
        slug: "any-buy", trigger_type: "purchase_item",
        trigger_data: {}, xp_reward: 5)
      notifs = checker.check(:purchase_item, item_name: "anything")
      expect(notifs.size).to eq(1)
    end
  end

  describe "missions_completed_count" do
    it "is in CUMULATIVE_TRIGGERS" do
      expect(GridAchievement::CUMULATIVE_TRIGGERS).to include("missions_completed_count")
    end

    it "counts turn_in_count summed across all completed hackr missions" do
      mission_a = create(:grid_mission)
      mission_b = create(:grid_mission, :repeatable)
      create(:grid_hackr_mission, :completed, grid_hackr: hackr, grid_mission: mission_a, turn_in_count: 1)
      create(:grid_hackr_mission, :completed, grid_hackr: hackr, grid_mission: mission_b, turn_in_count: 3)

      ach = create(:grid_achievement,
        slug: "mission-vet", trigger_type: "missions_completed_count",
        trigger_data: {"count" => 3}, xp_reward: 50)

      progress = checker.progress(ach)
      expect(progress[:current]).to eq(4)
      expect(progress[:target]).to eq(3)
      expect(progress[:completed]).to eq(true)
    end
  end

  describe "mission_completed" do
    it "matches when mission_slug matches context" do
      ach = create(:grid_achievement,
        slug: "first-mission-done", trigger_type: "mission_completed",
        trigger_data: {"mission_slug" => "first-contact"}, xp_reward: 50)

      notifs = checker.check(:mission_completed, mission_slug: "first-contact")
      expect(notifs.size).to eq(1)
      expect(hackr.grid_hackr_achievements.pluck(:grid_achievement_id)).to include(ach.id)
    end

    it "does not match when mission_slug differs" do
      create(:grid_achievement,
        slug: "specific-mission", trigger_type: "mission_completed",
        trigger_data: {"mission_slug" => "other-mission"})

      notifs = checker.check(:mission_completed, mission_slug: "first-contact")
      expect(notifs).to be_empty
    end
  end
end
