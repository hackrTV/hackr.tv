require "rails_helper"

RSpec.describe Grid::MissionRewardGranter do
  let(:hackr) { create(:grid_hackr) }
  let!(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }
  let!(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }
  let(:faction) { create(:grid_faction, slug: "hackrcore", name: "Hackrcore") }
  let(:mission) { create(:grid_mission) }
  let(:hackr_mission) { create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission) }

  before do
    # Fund the gameplay pool so mint_gameplay! can succeed.
    genesis_source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: genesis_source, to_cache: gameplay_pool, amount: 1_000_000,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  describe "#grant!" do
    it "marks the hackr_mission completed and increments turn_in_count" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "xp", amount: 50)
      described_class.new(hackr, hackr_mission).grant!
      hackr_mission.reload
      expect(hackr_mission.status).to eq("completed")
      expect(hackr_mission.completed_at).not_to be_nil
      expect(hackr_mission.turn_in_count).to eq(1)
    end

    it "grants XP via hackr.grant_xp!" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "xp", amount: 100)
      expect {
        described_class.new(hackr, hackr_mission).grant!
        hackr.reload
      }.to change { hackr.stat("xp") }.by(100)
    end

    it "mints CRED to the default cache" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "cred", amount: 40)
      expect {
        described_class.new(hackr, hackr_mission).grant!
      }.to change { cache.reload.balance }.by(40)
    end

    it "skips CRED mint when default cache is abandoned (rest still commits)" do
      cache.update!(status: "abandoned")
      create(:grid_mission_reward, grid_mission: mission, reward_type: "xp", amount: 10)
      create(:grid_mission_reward, grid_mission: mission, reward_type: "cred", amount: 50)

      expect {
        described_class.new(hackr, hackr_mission).grant!
        hackr.reload
      }.to change { hackr.stat("xp") }.by(10)

      expect(cache.reload.balance).to eq(0)
    end

    it "grants faction rep via ReputationService" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "faction_rep", amount: 25, target_slug: faction.slug)

      described_class.new(hackr, hackr_mission).grant!
      rep = hackr.grid_hackr_reputations.find_by(subject: faction)
      expect(rep.value).to eq(25)
    end

    it "creates a GridItem for item_grant rewards" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "item_grant", target_slug: "Reward Core", amount: 100, quantity: 2)

      expect {
        described_class.new(hackr, hackr_mission).grant!
      }.to change(GridItem, :count).by(1)

      item = hackr.grid_items.last
      expect(item.name).to eq("Reward Core")
      expect(item.quantity).to eq(2)
    end

    it "routes grant_achievement through AchievementAwarder" do
      ach = create(:grid_achievement, slug: "mission-badge", trigger_type: "manual", xp_reward: 5, cred_reward: 0)
      create(:grid_mission_reward, grid_mission: mission, reward_type: "grant_achievement", target_slug: ach.slug)

      expect {
        described_class.new(hackr, hackr_mission).grant!
      }.to change { hackr.grid_hackr_achievements.count }.by(1)
    end

    it "broadcasts mission_completed to the AchievementChannel stream" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "xp", amount: 10)

      expect(ActionCable.server).to receive(:broadcast).with(
        "achievement_channel_#{hackr.id}",
        hash_including(type: "mission_completed")
      )
      described_class.new(hackr, hackr_mission).grant!
    end

    it "advances reach_clearance objectives on OTHER active missions when XP triggers a level-up" do
      # Mission A: one XP reward that pushes the hackr past CL1 (10 XP).
      create(:grid_mission_reward, grid_mission: mission, reward_type: "xp", amount: 50)

      # Mission B: an independent active mission with a reach_clearance
      # objective that becomes satisfied once the hackr hits CL1.
      mission_b = create(:grid_mission, slug: "sibling-mission")
      obj_b = create(:grid_mission_objective, grid_mission: mission_b,
        objective_type: "reach_clearance", target_count: 1, label: "Reach CL1")
      hackr_mission_b = create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission_b)

      outcome = described_class.new(hackr, hackr_mission).grant!

      hackr_obj_b = hackr_mission_b.grid_hackr_mission_objectives.find_by(grid_mission_objective: obj_b)
      expect(hackr_obj_b).not_to be_nil
      expect(hackr_obj_b.completed_at).not_to be_nil
      expect(outcome[:progressor_notifs].join).to include("Reach CL1")
    end

    it "advances reach_rep objectives on OTHER active missions when the mission grants faction rep" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "faction_rep", amount: 50, target_slug: faction.slug)

      mission_b = create(:grid_mission, slug: "rep-sibling")
      obj_b = create(:grid_mission_objective, grid_mission: mission_b,
        objective_type: "reach_rep", target_slug: faction.slug, target_count: 25, label: "Gain 25 rep")
      hackr_mission_b = create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission_b)

      outcome = described_class.new(hackr, hackr_mission).grant!

      hackr_obj_b = hackr_mission_b.grid_hackr_mission_objectives.find_by(grid_mission_objective: obj_b)
      expect(hackr_obj_b).not_to be_nil
      expect(hackr_obj_b.completed_at).not_to be_nil
      expect(outcome[:progressor_notifs].join).to include("Gain 25 rep")
    end

    it "returns a notification_html block" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "xp", amount: 50)
      result = described_class.new(hackr, hackr_mission).grant!
      expect(result[:notification_html]).to include("MISSION COMPLETE")
      expect(result[:notification_html]).to include(mission.name)
      expect(result[:notification_html]).to include("+50 XP")
    end
  end
end
