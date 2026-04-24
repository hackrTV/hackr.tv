# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BREACH Phase 2B — Encounter Infrastructure" do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:deck_def) do
    create(:grid_item_definition, :gear,
      slug: "test-deck-2b",
      name: "Test Deck",
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 128, "battery_current" => 128, "module_slot_count" => 1, "effects" => {}})
  end

  let!(:deck) do
    item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    item.update!(equipped_slot: "deck")
    item
  end

  let(:software_def) do
    create(:grid_item_definition,
      slug: "test-sw-2b",
      name: "Test Program",
      item_type: "software",
      properties: {"software_category" => "offensive", "slot_cost" => 1, "battery_cost" => 10, "effect_type" => "damage", "effect_magnitude" => 20, "level" => 1})
  end

  let!(:software) do
    item = create(:grid_item, :in_inventory, grid_item_definition: software_def, grid_hackr: hackr)
    item.update!(deck_id: deck.id)
    item
  end

  let(:template) { create(:grid_breach_template, cooldown_min: 60, cooldown_max: 120) }

  # Helper: start a breach and return the breach record
  def start_breach!(enc: nil, tmpl: nil)
    tmpl ||= template
    enc ||= create(:grid_breach_encounter, grid_breach_template: tmpl, grid_room: room)
    result = Grid::BreachService.start!(hackr: hackr, encounter: enc)
    result.hackr_breach
  end

  describe "GridBreachEncounter model" do
    it "validates state inclusion" do
      enc = build(:grid_breach_encounter, state: "invalid")
      expect(enc).not_to be_valid
      expect(enc.errors[:state]).to be_present
    end

    it "valid with allowed states" do
      GridBreachEncounter::STATES.each do |s|
        enc = build(:grid_breach_encounter, state: s)
        expect(enc).to be_valid
      end
    end

    it "delegates name and tier_label to template" do
      enc = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room)
      expect(enc.name).to eq(template.name)
      expect(enc.tier_label).to eq(template.tier_label)
    end
  end

  describe "GridHackrBreachLog model" do
    it "validates action_type inclusion" do
      breach = start_breach!
      log = GridHackrBreachLog.new(
        grid_hackr_breach: breach,
        round: 1,
        action_type: "invalid",
        result: {}
      )
      expect(log).not_to be_valid
    end

    it "saves valid log entries" do
      breach = start_breach!
      log = GridHackrBreachLog.create!(
        grid_hackr_breach: breach,
        round: 1,
        action_type: "exec",
        target: "0",
        program_slug: "test-sw-2b",
        result: {hit: true, damage: 20}
      )
      expect(log).to be_persisted
    end
  end

  describe "available_encounters" do
    it "returns available encounters in a room" do
      enc = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room)
      result = Grid::BreachService.available_encounters(room: room)
      expect(result).to include(enc)
    end

    it "excludes depleted encounters" do
      create(:grid_breach_encounter, grid_breach_template: template, grid_room: room, state: "depleted")
      result = Grid::BreachService.available_encounters(room: room)
      expect(result).to be_empty
    end

    it "excludes encounters on cooldown" do
      create(:grid_breach_encounter, grid_breach_template: template, grid_room: room,
        state: "cooldown", cooldown_until: 10.minutes.from_now)
      result = Grid::BreachService.available_encounters(room: room)
      expect(result).to be_empty
    end

    it "auto-expires cooldowns" do
      enc = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room,
        state: "cooldown", cooldown_until: 1.minute.ago)
      result = Grid::BreachService.available_encounters(room: room)
      expect(result).to include(enc)
      expect(enc.reload.state).to eq("available")
    end

    it "filters by hackr clearance" do
      high_cl = create(:grid_breach_template, min_clearance: 50)
      create(:grid_breach_encounter, grid_breach_template: high_cl, grid_room: room)
      result = Grid::BreachService.available_encounters(room: room, hackr: hackr)
      expect(result).to be_empty
    end

    it "excludes unpublished templates" do
      unpub = create(:grid_breach_template, :unpublished)
      create(:grid_breach_encounter, grid_breach_template: unpub, grid_room: room)
      result = Grid::BreachService.available_encounters(room: room)
      expect(result).to be_empty
    end

    it "returns multiple encounters sorted by template position" do
      t1 = create(:grid_breach_template, position: 2)
      t2 = create(:grid_breach_template, position: 1)
      e1 = create(:grid_breach_encounter, grid_breach_template: t1, grid_room: room)
      e2 = create(:grid_breach_encounter, grid_breach_template: t2, grid_room: room)
      result = Grid::BreachService.available_encounters(room: room)
      expect(result).to eq([e2, e1])
    end
  end

  describe "encounter state transitions" do
    let(:enc) { create(:grid_breach_encounter, grid_breach_template: template, grid_room: room) }

    it "marks encounter active on breach start" do
      start_breach!(enc: enc)
      expect(enc.reload.state).to eq("active")
    end

    it "transitions encounter to cooldown on success" do
      breach = start_breach!(enc: enc)

      # Destroy all protocols to trigger success
      breach.grid_breach_protocols.each { |p| p.update_columns(health: 0, state: "destroyed") }
      Grid::BreachService.resolve_success!(hackr_breach: breach)

      enc.reload
      expect(enc.state).to eq("cooldown")
      expect(enc.cooldown_until).to be_present
      expect(enc.cooldown_until).to be > Time.current
    end

    it "transitions encounter to cooldown on failure" do
      breach = start_breach!(enc: enc)
      Grid::BreachService.resolve_failure!(hackr_breach: breach)

      enc.reload
      expect(enc.state).to eq("cooldown")
    end

    it "transitions encounter to cooldown on jackout" do
      start_breach!(enc: enc)
      Grid::BreachService.jackout!(hackr: hackr)

      enc.reload
      expect(enc.state).to eq("cooldown")
    end

    it "links breach to encounter" do
      breach = start_breach!(enc: enc)
      expect(breach.grid_breach_encounter).to eq(enc)
    end
  end

  describe "cooldown randomization" do
    it "sets cooldown_until within template range" do
      enc = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room)
      breach = start_breach!(enc: enc)

      # Fail the breach to trigger cooldown
      Grid::BreachService.resolve_failure!(hackr_breach: breach)

      enc.reload
      remaining = enc.cooldown_until - Time.current
      expect(remaining).to be_between(template.cooldown_min - 1, template.cooldown_max + 1)
    end
  end

  describe "cooldown check_cooldown!" do
    it "transitions from cooldown to available when expired" do
      enc = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room,
        state: "cooldown", cooldown_until: 1.minute.ago)
      enc.check_cooldown!
      expect(enc.state).to eq("available")
      expect(enc.cooldown_until).to be_nil
    end

    it "stays in cooldown when not expired" do
      enc = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room,
        state: "cooldown", cooldown_until: 10.minutes.from_now)
      enc.check_cooldown!
      expect(enc.state).to eq("cooldown")
    end
  end

  describe "breach action logging" do
    let(:enc) { create(:grid_breach_encounter, grid_breach_template: template, grid_room: room) }
    let!(:breach) { start_breach!(enc: enc) }

    it "logs exec actions" do
      Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Test Program",
        target_position: 0
      )

      logs = GridHackrBreachLog.where(grid_hackr_breach: breach)
      expect(logs.count).to eq(1)
      log = logs.first
      expect(log.action_type).to eq("exec")
      expect(log.round).to eq(1)
      expect(log.target).to eq("0")
      expect(log.program_slug).to eq("test-sw-2b")
      expect(log.result["hit"]).to be true
    end

    it "logs analyze actions" do
      Grid::BreachActionService.analyze!(hackr: hackr, target_position: 0)

      log = GridHackrBreachLog.last
      expect(log.action_type).to eq("analyze")
      expect(log.target).to eq("0")
      expect(log.result["level_reached"]).to eq(1)
    end

    it "logs reroute actions" do
      # Need an active protocol
      protocol = breach.grid_breach_protocols.find_by(position: 0)
      protocol.update_columns(state: "active") if protocol.state != "active"

      Grid::BreachActionService.reroute!(hackr: hackr, target_position: 0)

      log = GridHackrBreachLog.last
      expect(log.action_type).to eq("reroute")
      expect(log.target).to eq("0")
    end

    it "logs jackout actions" do
      Grid::BreachService.jackout!(hackr: hackr)

      log = GridHackrBreachLog.last
      expect(log.action_type).to eq("jackout")
      expect(log.result["clean"]).to be true
    end

    it "cascades log deletion with breach" do
      Grid::BreachActionService.exec!(hackr: hackr, program_name: "Test Program", target_position: 0)
      expect { breach.destroy! }.to change(GridHackrBreachLog, :count).by(-1)
    end
  end

  describe "multi-encounter room selection" do
    let(:t1) { create(:grid_breach_template) }
    let(:t2) { create(:grid_breach_template) }
    let!(:enc1) { create(:grid_breach_encounter, grid_breach_template: t1, grid_room: room) }
    let!(:enc2) { create(:grid_breach_encounter, grid_breach_template: t2, grid_room: room) }

    it "room.breachable? returns true with encounters" do
      expect(room.breachable?).to be true
    end

    it "room.breachable? returns false without encounters" do
      empty_room = create(:grid_room, grid_zone: zone)
      expect(empty_room.breachable?).to be false
    end
  end

  describe "encounter concurrency" do
    it "prevents concurrent breach start on same encounter" do
      enc = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room)
      start_breach!(enc: enc)

      # Encounter should be active, not available for another hackr
      expect(enc.reload.state).to eq("active")
      expect(enc).not_to be_available
    end
  end
end
