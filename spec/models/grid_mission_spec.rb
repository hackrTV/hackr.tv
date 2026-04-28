# == Schema Information
#
# Table name: grid_missions
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  dialogue_path       :json
#  min_clearance       :integer          default(0), not null
#  min_rep_value       :integer          default(0), not null
#  name                :string           not null
#  position            :integer          default(0), not null
#  published           :boolean          default(FALSE), not null
#  repeatable          :boolean          default(FALSE), not null
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  giver_mob_id        :integer
#  grid_mission_arc_id :integer
#  min_rep_faction_id  :integer
#  prereq_mission_id   :integer
#
# Indexes
#
#  index_grid_missions_on_giver_mob_id         (giver_mob_id)
#  index_grid_missions_on_grid_mission_arc_id  (grid_mission_arc_id)
#  index_grid_missions_on_min_rep_faction_id   (min_rep_faction_id)
#  index_grid_missions_on_prereq_mission_id    (prereq_mission_id)
#  index_grid_missions_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  giver_mob_id         (giver_mob_id => grid_mobs.id) ON DELETE => nullify
#  grid_mission_arc_id  (grid_mission_arc_id => grid_mission_arcs.id) ON DELETE => nullify
#  min_rep_faction_id   (min_rep_faction_id => grid_factions.id) ON DELETE => nullify
#  prereq_mission_id    (prereq_mission_id => grid_missions.id) ON DELETE => nullify
#
require "rails_helper"

RSpec.describe GridMission do
  describe "validations" do
    it "requires a slug" do
      expect(build(:grid_mission, slug: nil)).not_to be_valid
    end

    it "requires a unique slug" do
      create(:grid_mission, slug: "dupe")
      expect(build(:grid_mission, slug: "dupe")).not_to be_valid
    end

    it "requires a giver_mob when published" do
      mission = build(:grid_mission, giver_mob: nil, published: true)
      expect(mission).not_to be_valid
      expect(mission.errors[:giver_mob_id]).to include(/required for published/)
    end

    it "allows nil giver_mob when unpublished (draft)" do
      mission = build(:grid_mission, giver_mob: nil, published: false)
      expect(mission).to be_valid
    end

    it "rejects a prereq that points to itself" do
      mission = create(:grid_mission)
      mission.prereq_mission_id = mission.id
      expect(mission).not_to be_valid
      expect(mission.errors[:prereq_mission_id]).to include(/itself/)
    end
  end

  describe "associations + cascade" do
    it "destroys objectives and rewards on destroy" do
      mission = create(:grid_mission)
      create(:grid_mission_objective, grid_mission: mission)
      create(:grid_mission_reward, grid_mission: mission)

      expect { mission.destroy! }
        .to change(GridMissionObjective, :count).by(-1)
        .and change(GridMissionReward, :count).by(-1)
    end

    it "destroys hackr instances on destroy" do
      mission = create(:grid_mission)
      create(:grid_hackr_mission, grid_mission: mission)

      expect { mission.destroy! }.to change(GridHackrMission, :count).by(-1)
    end
  end

  it "uses slug as to_param" do
    mission = create(:grid_mission, slug: "hello-world")
    expect(mission.to_param).to eq("hello-world")
  end
end

RSpec.describe GridMissionArc do
  it "validates uniqueness of slug" do
    create(:grid_mission_arc, slug: "arc-dupe")
    expect(build(:grid_mission_arc, slug: "arc-dupe")).not_to be_valid
  end
end

RSpec.describe GridMissionObjective do
  it "validates objective_type against allowlist" do
    obj = build(:grid_mission_objective, objective_type: "bogus")
    expect(obj).not_to be_valid
    expect(obj.errors[:objective_type]).to be_present
  end

  it "requires target_count > 0" do
    obj = build(:grid_mission_objective, target_count: 0)
    expect(obj).not_to be_valid
  end
end

RSpec.describe GridMissionReward do
  it "validates reward_type against allowlist" do
    r = build(:grid_mission_reward, reward_type: "bogus")
    expect(r).not_to be_valid
  end
end

RSpec.describe GridHackrMission do
  describe "#all_objectives_completed?" do
    let(:mission) { create(:grid_mission) }
    let!(:obj1) { create(:grid_mission_objective, grid_mission: mission) }
    let!(:obj2) { create(:grid_mission_objective, :talk_npc, grid_mission: mission) }
    let(:hackr) { create(:grid_hackr) }
    let(:hackr_mission) { create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission) }

    it "is false when no objectives have been completed" do
      create(:grid_hackr_mission_objective, grid_hackr_mission: hackr_mission, grid_mission_objective: obj1)
      create(:grid_hackr_mission_objective, grid_hackr_mission: hackr_mission, grid_mission_objective: obj2)
      expect(hackr_mission.all_objectives_completed?).to eq(false)
    end

    it "is true only when ALL objectives have completed_at set" do
      create(:grid_hackr_mission_objective, :completed, grid_hackr_mission: hackr_mission, grid_mission_objective: obj1)
      create(:grid_hackr_mission_objective, :completed, grid_hackr_mission: hackr_mission, grid_mission_objective: obj2)
      expect(hackr_mission.all_objectives_completed?).to eq(true)
    end

    it "is false when only some objectives are complete" do
      create(:grid_hackr_mission_objective, :completed, grid_hackr_mission: hackr_mission, grid_mission_objective: obj1)
      create(:grid_hackr_mission_objective, grid_hackr_mission: hackr_mission, grid_mission_objective: obj2)
      expect(hackr_mission.all_objectives_completed?).to eq(false)
    end
  end

  it "prevents two active instances of the same mission" do
    hackr = create(:grid_hackr)
    mission = create(:grid_mission)
    create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission, status: "active")

    dup = build(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission, status: "active")
    expect(dup).not_to be_valid
    expect(dup.errors[:base].join).to match(/active instance/)
  end

  it "allows a fresh active instance when the previous is completed" do
    hackr = create(:grid_hackr)
    mission = create(:grid_mission, :repeatable)
    create(:grid_hackr_mission, :completed, grid_hackr: hackr, grid_mission: mission)

    fresh = build(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission, status: "active")
    expect(fresh).to be_valid
  end
end
