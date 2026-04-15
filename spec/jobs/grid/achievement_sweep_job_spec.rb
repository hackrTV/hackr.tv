require "rails_helper"

RSpec.describe Grid::AchievementSweepJob do
  let(:hackr) { create(:grid_hackr) }

  it "no-ops for an unknown hackr_id" do
    expect { described_class.perform_now(999_999) }.not_to raise_error
  end

  it "invokes the checker for every cumulative trigger" do
    checker = instance_double(Grid::AchievementChecker)
    allow(Grid::AchievementChecker).to receive(:new).with(hackr).and_return(checker)

    GridAchievement::CUMULATIVE_TRIGGERS.each do |trigger_type|
      expect(checker).to receive(:check).with(trigger_type).and_return([])
    end

    described_class.perform_now(hackr.id)
  end

  it "retroactively awards a cumulative achievement reached between sessions" do
    create(:grid_achievement,
      slug: "rooms-sweep",
      trigger_type: "rooms_visited",
      trigger_data: {"count" => 5},
      xp_reward: 25)

    hackr.set_stat!("rooms_visited", 5)

    expect { described_class.perform_now(hackr.id) }
      .to change { hackr.grid_hackr_achievements.count }.by(1)
  end
end
