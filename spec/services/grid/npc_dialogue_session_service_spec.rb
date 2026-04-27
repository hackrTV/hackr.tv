require "rails_helper"

RSpec.describe Grid::NpcDialogueSessionService do
  let(:zone) { create(:grid_zone) }
  let(:original_room) { create(:grid_room, grid_zone: zone, name: "Original Room") }
  let(:mob_room) { create(:grid_room, grid_zone: zone, name: "Mob Room") }
  let(:hackr) { create(:grid_hackr, current_room: original_room, zone_entry_room: original_room) }
  let(:mob) { create(:grid_mob, grid_room: mob_room, name: "Test NPC") }
  let(:service) { described_class.new(hackr) }

  describe "#start!" do
    it "warps hackr to mob's room" do
      service.start!(mob: mob)
      hackr.reload
      expect(hackr.current_room_id).to eq(mob_room.id)
    end

    it "updates zone_entry_room_id to mob's room" do
      service.start!(mob: mob)
      hackr.reload
      expect(hackr.zone_entry_room_id).to eq(mob_room.id)
    end

    it "stores snapshot in hackr stats" do
      service.start!(mob: mob)
      hackr.reload
      snapshot = hackr.stats["npc_tester_snapshot"]
      expect(snapshot).to be_present
      expect(snapshot["origin_room_id"]).to eq(original_room.id)
      expect(snapshot["origin_zone_entry_room_id"]).to eq(original_room.id)
      expect(snapshot["mob_id"]).to eq(mob.id)
      expect(snapshot["started_at"]).to be_present
    end

    it "raises AlreadyInBreach if hackr is in breach" do
      template = create(:grid_breach_template)
      create(:grid_hackr_breach, grid_hackr: hackr, grid_breach_template: template)
      hackr.reload

      expect { service.start!(mob: mob) }
        .to raise_error(Grid::NpcDialogueSessionService::AlreadyInBreach)
    end

    it "restores stale session before starting new one" do
      # Start first session
      service.start!(mob: mob)
      hackr.reload
      expect(hackr.current_room_id).to eq(mob_room.id)

      # Start second session with different mob in a third room
      third_room = create(:grid_room, grid_zone: zone, name: "Third Room")
      other_mob = create(:grid_mob, grid_room: third_room, name: "Other NPC")

      # Hackr is now at mob_room from first session
      # Starting new session should restore to original_room first, then warp to third_room
      service.start!(mob: other_mob)
      hackr.reload

      expect(hackr.current_room_id).to eq(third_room.id)
      snapshot = hackr.stats["npc_tester_snapshot"]
      # Stale session restored hackr to original_room before new snapshot was taken
      expect(snapshot["origin_room_id"]).to eq(original_room.id)
    end
  end

  describe "#restore!" do
    before { service.start!(mob: mob) }

    it "warps hackr back to original room" do
      service.restore!
      hackr.reload
      expect(hackr.current_room_id).to eq(original_room.id)
    end

    it "restores zone_entry_room_id" do
      service.restore!
      hackr.reload
      expect(hackr.zone_entry_room_id).to eq(original_room.id)
    end

    it "clears the snapshot from stats" do
      service.restore!
      hackr.reload
      expect(hackr.stats["npc_tester_snapshot"]).to be_nil
    end

    it "is a no-op when no snapshot exists" do
      service.restore!
      hackr.reload
      # Call again — should not raise or change anything
      expect { service.restore! }.not_to raise_error
      hackr.reload
      expect(hackr.current_room_id).to eq(original_room.id)
    end
  end

  describe "#active?" do
    it "returns false before start" do
      expect(service.active?).to be false
    end

    it "returns true after start" do
      service.start!(mob: mob)
      expect(service.active?).to be true
    end

    it "returns false after restore" do
      service.start!(mob: mob)
      service.restore!
      # Need fresh service to re-read stats
      hackr.reload
      expect(described_class.new(hackr).active?).to be false
    end
  end
end
