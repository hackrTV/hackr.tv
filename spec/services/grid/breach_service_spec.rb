# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::BreachService do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:template) { create(:grid_breach_template) }

  let(:deck_def) do
    create(:grid_item_definition, :gear,
      slug: "test-deck",
      name: "Test Deck",
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "firmware_slot_count" => 1, "effects" => {}})
  end

  let!(:deck) do
    item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    item.update!(equipped_slot: "deck")
    item
  end

  describe ".start!" do
    it "creates an active breach with protocols" do
      result = described_class.start!(hackr: hackr, template: template)

      expect(result.hackr_breach).to be_a(GridHackrBreach)
      expect(result.hackr_breach.state).to eq("active")
      expect(result.hackr_breach.detection_level).to eq(0)
      expect(result.hackr_breach.round_number).to eq(1)
      expect(result.hackr_breach.origin_room_id).to eq(room.id)
      expect(result.protocols.size).to eq(2) # trace + feedback
      expect(result.display).to include("B R E A C H")
    end

    it "raises AlreadyInBreach when hackr has an active breach" do
      described_class.start!(hackr: hackr, template: template)
      expect {
        described_class.start!(hackr: hackr, template: template)
      }.to raise_error(Grid::BreachService::AlreadyInBreach)
    end

    it "raises NoDeckEquipped when no deck is equipped" do
      deck.update!(equipped_slot: nil)
      expect {
        described_class.start!(hackr: hackr, template: template)
      }.to raise_error(Grid::BreachService::NoDeckEquipped)
    end

    it "raises ClearanceBlocked when hackr clearance is insufficient" do
      high_cl_template = create(:grid_breach_template, min_clearance: 50)
      expect {
        described_class.start!(hackr: hackr, template: high_cl_template)
      }.to raise_error(Grid::BreachService::ClearanceBlocked)
    end

    it "raises TemplateGated for unpublished templates" do
      unpub = create(:grid_breach_template, :unpublished)
      expect {
        described_class.start!(hackr: hackr, template: unpub)
      }.to raise_error(Grid::BreachService::TemplateGated)
    end
  end

  describe ".end_round!" do
    let!(:breach_result) { described_class.start!(hackr: hackr, template: template) }
    let(:breach) { breach_result.hackr_breach }

    before do
      # Consume all actions to trigger end_round
      breach.update!(actions_remaining: 0)
    end

    it "increments detection level" do
      old_detection = breach.detection_level
      result = described_class.end_round!(hackr_breach: breach)
      expect(result.hackr_breach.detection_level).to be > old_detection
    end

    it "increments round number" do
      result = described_class.end_round!(hackr_breach: breach)
      expect(result.hackr_breach.round_number).to eq(2)
    end

    it "sets new actions for the round" do
      result = described_class.end_round!(hackr_breach: breach)
      expect(result.hackr_breach.actions_remaining).to be >= 1
    end

    it "triggers failure when detection reaches 100" do
      breach.update!(detection_level: 96)
      result = described_class.end_round!(hackr_breach: breach)
      expect(result.state).to eq(:failure)
      expect(breach.reload.state).to eq("failure")
    end
  end

  describe ".resolve_success!" do
    let!(:breach_result) { described_class.start!(hackr: hackr, template: template) }
    let(:breach) { breach_result.hackr_breach }

    it "grants XP and CRED rewards" do
      old_xp = hackr.stat("xp")
      result = described_class.resolve_success!(hackr_breach: breach)

      expect(result.xp_awarded).to eq(template.xp_reward)
      expect(result.hackr_breach.state).to eq("success")
      expect(hackr.reload.stat("xp")).to be > old_xp
      expect(hackr.stat("breach_completed_count")).to eq(1)
    end
  end

  describe ".resolve_failure!" do
    let!(:breach_result) { described_class.start!(hackr: hackr, template: template) }
    let(:breach) { breach_result.hackr_breach }

    it "drains vitals and sets failure state" do
      old_energy = hackr.stat("energy")
      old_psyche = hackr.stat("psyche")

      result = described_class.resolve_failure!(hackr_breach: breach)

      expect(result.hackr_breach.state).to eq("failure")
      expect(hackr.reload.stat("energy")).to be < old_energy
      expect(hackr.stat("psyche")).to be < old_psyche
    end

    it "applies zone lockout for standard tier" do
      result = described_class.resolve_failure!(hackr_breach: breach)
      expect(result.zone_lockout_minutes).to be_present
      lockout_key = "zone_lockout_#{zone.id}"
      expect(hackr.reload.stat(lockout_key).to_i).to be > Time.current.to_i
    end

    it "does not apply zone lockout for ambient tier" do
      ambient_template = create(:grid_breach_template, :ambient)
      ambient_breach = described_class.start!(hackr: hackr.tap { |h| breach.update!(state: "failure") }, template: ambient_template)
      result = described_class.resolve_failure!(hackr_breach: ambient_breach.hackr_breach)
      expect(result.zone_lockout_minutes).to be_nil
    end
  end

  describe ".jackout!" do
    let!(:breach_result) { described_class.start!(hackr: hackr, template: template) }

    it "clean jackout before PNR" do
      result = described_class.jackout!(hackr: hackr)
      expect(result.clean).to be true
      expect(result.hackr_breach.state).to eq("jacked_out")
    end

    it "dirty jackout after PNR" do
      breach_result.hackr_breach.update!(detection_level: 80) # past 75% PNR
      result = described_class.jackout!(hackr: hackr)
      expect(result.clean).to be false
      expect(result.vitals_hit.size).to be >= 2
    end

    it "raises NotInBreach when no active breach" do
      expect {
        hackr2 = create(:grid_hackr)
        described_class.jackout!(hackr: hackr2)
      }.to raise_error(Grid::BreachService::NotInBreach)
    end
  end

  describe ".breach_rank" do
    it "returns Script Kiddie for clearance 0" do
      rank = described_class.breach_rank(0)
      expect(rank[:rank]).to eq("Script Kiddie")
      expect(rank[:ceiling]).to eq(1)
    end

    it "returns Netcutter for clearance 20" do
      rank = described_class.breach_rank(20)
      expect(rank[:rank]).to eq("Netcutter")
      expect(rank[:ceiling]).to eq(4)
    end

    it "returns max rank for clearance 99" do
      rank = described_class.breach_rank(99)
      expect(rank[:ceiling]).to eq(16)
    end
  end
end
