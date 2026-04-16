require "rails_helper"

RSpec.describe Grid::MissionProgressor do
  let(:hackr) { create(:grid_hackr) }
  let(:mission) { create(:grid_mission) }
  let!(:hackr_mission) { create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission) }
  let(:progressor) { described_class.new(hackr) }

  def make_objective(type, **attrs)
    create(:grid_mission_objective, grid_mission: mission, objective_type: type, **attrs)
  end

  describe ":visit_room" do
    it "completes when target_slug matches the room_slug" do
      objective = make_objective("visit_room", target_slug: "the-blacksite", label: "Reach Blacksite")
      notifs = progressor.record(:visit_room, room_slug: "the-blacksite")

      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective)
      expect(hobj.completed_at).not_to be_nil
      expect(notifs.join).to include("Reach Blacksite")
    end

    it "does nothing when target_slug doesn't match" do
      make_objective("visit_room", target_slug: "other-room", label: "Go elsewhere")
      notifs = progressor.record(:visit_room, room_slug: "the-blacksite")

      expect(notifs).to be_empty
      expect(hackr_mission.grid_hackr_mission_objectives.count).to eq(0)
    end

    it "is silent when an already-complete objective is re-triggered (no duplicate notif)" do
      make_objective("visit_room", target_slug: "the-blacksite")
      progressor.record(:visit_room, room_slug: "the-blacksite")
      second = progressor.record(:visit_room, room_slug: "the-blacksite")

      expect(second).to be_empty
    end
  end

  describe ":collect_item (cumulative count)" do
    it "accumulates progress across multiple takes until target_count is reached" do
      objective = make_objective("collect_item", target_slug: "Signal Shard", target_count: 3, label: "Collect 3 shards")

      progressor.record(:collect_item, item_name: "Signal Shard")
      progressor.record(:collect_item, item_name: "Signal Shard")
      expect(hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective).progress).to eq(2)

      notifs = progressor.record(:collect_item, item_name: "Signal Shard")
      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective).reload
      expect(hobj.progress).to eq(3)
      expect(hobj.completed_at).not_to be_nil
      expect(notifs).not_to be_empty
    end
  end

  describe ":deliver_item (two-dimensional matching)" do
    # deliver_item objectives match on BOTH the item name (target_slug)
    # AND the destination NPC. By convention the destination is the
    # mission's giver_mob — not a separate column — so a missed-target
    # deliver doesn't advance the objective.
    let(:giver_room) { create(:grid_room) }
    let(:giver_mob) { create(:grid_mob, :quest_giver, name: "Courier", grid_room: giver_room) }
    let(:other_mob) { create(:grid_mob, name: "Stranger", grid_room: giver_room) }
    let(:mission) { create(:grid_mission, giver_mob: giver_mob) }

    it "advances when both the item AND the mission giver match" do
      objective = create(:grid_mission_objective, :deliver_item,
        grid_mission: mission, target_slug: "Signal Shard", label: "Deliver shard")

      notifs = described_class.new(hackr).record(:deliver_item, item_name: "Signal Shard", npc_name: "Courier")

      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective)
      expect(hobj).not_to be_nil
      expect(hobj.completed_at).not_to be_nil
      expect(notifs.join).to include("Deliver shard")
    end

    it "does NOT advance when the item matches but the NPC is not the giver" do
      create(:grid_mission_objective, :deliver_item,
        grid_mission: mission, target_slug: "Signal Shard", label: "Deliver shard")

      notifs = described_class.new(hackr).record(:deliver_item, item_name: "Signal Shard", npc_name: "Stranger")

      expect(notifs).to be_empty
      expect(hackr_mission.grid_hackr_mission_objectives.count).to eq(0)
    end

    it "does NOT advance when the NPC matches but the item is wrong" do
      create(:grid_mission_objective, :deliver_item,
        grid_mission: mission, target_slug: "Signal Shard", label: "Deliver shard")

      notifs = described_class.new(hackr).record(:deliver_item, item_name: "Fake Shard", npc_name: "Courier")

      expect(notifs).to be_empty
    end

    it "wildcards the item when target_slug is blank (any item delivered to giver)" do
      objective = create(:grid_mission_objective, :deliver_item,
        grid_mission: mission, target_slug: nil, label: "Deliver anything")

      described_class.new(hackr).record(:deliver_item, item_name: "Whatever", npc_name: "Courier")

      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective)
      expect(hobj&.completed_at).not_to be_nil
    end

    it "accepts delivery to ANY NPC when the mission has no giver (giver-nil wildcard)" do
      mission.update!(giver_mob: nil, published: false)
      objective = create(:grid_mission_objective, :deliver_item,
        grid_mission: mission, target_slug: "Data Chip", label: "Drop the chip")

      described_class.new(hackr).record(:deliver_item, item_name: "Data Chip", npc_name: "Stranger")

      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective)
      expect(hobj&.completed_at).not_to be_nil
    end

    it "is case-insensitive on both item and NPC names" do
      objective = create(:grid_mission_objective, :deliver_item,
        grid_mission: mission, target_slug: "Signal Shard", label: "Deliver shard")

      described_class.new(hackr).record(:deliver_item, item_name: "SIGNAL SHARD", npc_name: "courier")

      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective)
      expect(hobj&.completed_at).not_to be_nil
    end
  end

  describe ":reach_clearance (threshold)" do
    it "completes when the provided value reaches target_count" do
      objective = make_objective("reach_clearance", target_slug: nil, target_count: 3, label: "Hit CL3")
      notifs = progressor.record(:reach_clearance, clearance: 5)

      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective)
      expect(hobj.completed_at).not_to be_nil
      expect(hobj.progress).to eq(3) # clamped to target
      expect(notifs).not_to be_empty
    end

    it "records progress below threshold without completing" do
      objective = make_objective("reach_clearance", target_count: 5, label: "Hit CL5")
      notifs = progressor.record(:reach_clearance, clearance: 2)

      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective)
      expect(hobj.progress).to eq(2)
      expect(hobj.completed_at).to be_nil
      expect(notifs).to be_empty
    end
  end

  describe ":spend_cred (accumulator)" do
    it "accumulates across multiple events" do
      objective = make_objective("spend_cred", target_count: 200, label: "Spend 200 CRED")

      progressor.record(:spend_cred, amount: 75)
      progressor.record(:spend_cred, amount: 75)
      expect(hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective).progress).to eq(150)

      progressor.record(:spend_cred, amount: 50)
      hobj = hackr_mission.grid_hackr_mission_objectives.find_by(grid_mission_objective: objective).reload
      expect(hobj.progress).to eq(200)
      expect(hobj.completed_at).not_to be_nil
    end
  end

  describe "READY notification" do
    it "emits a READY-for-turn-in notification when the last objective completes" do
      make_objective("visit_room", target_slug: "room-a", label: "A", position: 1)
      make_objective("visit_room", target_slug: "room-b", label: "B", position: 2)

      first_batch = progressor.record(:visit_room, room_slug: "room-a")
      expect(first_batch.join).to include("A")
      expect(first_batch.join).not_to include("READY FOR TURN-IN")

      # Discard progressor so memoized active_hackr_missions reflect the
      # just-saved objective row; mirrors real per-request lifecycle.
      final = described_class.new(hackr).record(:visit_room, room_slug: "room-b")
      expect(final.join).to include("B")
      expect(final.join).to include("READY FOR TURN-IN")
    end
  end

  it "no-ops for completed missions" do
    make_objective("visit_room", target_slug: "a")
    hackr_mission.update!(status: "completed", completed_at: Time.current)

    notifs = described_class.new(hackr).record(:visit_room, room_slug: "a")
    expect(notifs).to be_empty
  end
end
