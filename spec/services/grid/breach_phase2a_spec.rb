# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BREACH Phase 2A" do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:deck_def) do
    create(:grid_item_definition, :gear,
      slug: "test-deck-2a",
      name: "Test Deck",
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 128, "battery_current" => 128, "firmware_slot_count" => 1, "effects" => {}})
  end

  let!(:deck) do
    item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    item.update!(equipped_slot: "deck")
    item
  end

  let(:software_def) do
    create(:grid_item_definition,
      slug: "test-sw-2a",
      name: "Test Program",
      item_type: "software",
      properties: {"software_category" => "offensive", "slot_cost" => 1, "battery_cost" => 10, "effect_type" => "damage", "effect_magnitude" => 20, "level" => 1})
  end

  let!(:software) do
    item = create(:grid_item, :in_inventory, grid_item_definition: software_def, grid_hackr: hackr)
    item.update!(deck_id: deck.id)
    item
  end

  # Helper: start a breach and return the breach record
  def start_breach!(template: nil)
    template ||= create(:grid_breach_template)
    result = Grid::BreachService.start!(hackr: hackr, template: template)
    result.hackr_breach
  end

  describe "SPIKE Protocol" do
    let(:template) do
      create(:grid_breach_template, protocol_composition: [
        {"type" => "spike", "count" => 1, "health" => 30, "max_health" => 30, "charge_rounds" => 0}
      ])
    end

    it "drains HEALTH each round" do
      breach = start_breach!(template: template)
      old_health = hackr.stat("health")

      # Spend the action so round ends
      breach.update!(actions_remaining: 0)
      Grid::BreachService.end_round!(hackr_breach: breach)

      hackr.reload
      expect(hackr.stat("health")).to eq(old_health - 6)
    end

    it "has 'defensive' as default weakness" do
      expect(Grid::BreachProtocol::Engine.weakness_for("spike")).to eq("defensive")
    end
  end

  describe "PURGE Protocol" do
    let(:template) do
      create(:grid_breach_template, protocol_composition: [
        {"type" => "purge", "count" => 1, "health" => 30, "max_health" => 30, "charge_rounds" => 0}
      ])
    end

    it "degrades reward_multiplier each round" do
      breach = start_breach!(template: template)
      expect(breach.reward_multiplier).to eq(1.0)

      breach.update!(actions_remaining: 0)
      Grid::BreachService.end_round!(hackr_breach: breach)

      breach.reload
      expect(breach.reward_multiplier).to be_within(0.001).of(0.9)
    end

    it "compounds with multiple PURGE protocols" do
      double_purge = create(:grid_breach_template, protocol_composition: [
        {"type" => "purge", "count" => 2, "health" => 30, "max_health" => 30, "charge_rounds" => 0}
      ])
      breach = start_breach!(template: double_purge)

      breach.update!(actions_remaining: 0)
      Grid::BreachService.end_round!(hackr_breach: breach)

      breach.reload
      # Two PURGEs: 1.0 * 0.9 * 0.9 = 0.81
      expect(breach.reward_multiplier).to be_within(0.001).of(0.81)
    end

    it "has 'utility' as default weakness" do
      expect(Grid::BreachProtocol::Engine.weakness_for("purge")).to eq("utility")
    end
  end

  describe "Protocol Synergies" do
    describe "TRACE+TRACE detection doubling" do
      let(:template) do
        create(:grid_breach_template, base_detection_rate: 5, protocol_composition: [
          {"type" => "trace", "count" => 2, "health" => 50, "max_health" => 50, "charge_rounds" => 0}
        ])
      end

      it "doubles trace detection bonus with 2+ active TRACE" do
        breach = start_breach!(template: template)
        breach.update!(actions_remaining: 0)

        Grid::BreachService.end_round!(hackr_breach: breach)
        breach.reload

        # base_rate(5) + trace_count(2) * TRACE_BONUS(4) * 2(synergy) = 5 + 16 = 21
        expect(breach.detection_level).to eq(21)
      end

      it "stops doubling when one TRACE is destroyed mid-encounter" do
        breach = start_breach!(template: template)

        # Destroy one TRACE protocol
        trace = breach.grid_breach_protocols.where(protocol_type: "trace").first
        trace.update_columns(state: "destroyed", health: 0)

        breach.update!(actions_remaining: 0)
        old_detection = breach.detection_level

        Grid::BreachService.end_round!(hackr_breach: breach)
        breach.reload

        # Only 1 TRACE active: base_rate(5) + trace_count(1) * TRACE_BONUS(4) * 1(no synergy) = 5 + 4 = 9
        expect(breach.detection_level).to eq(old_detection + 9)
      end
    end

    describe "ADAPT gated by TRACE on low-tier encounters" do
      let(:template) do
        create(:grid_breach_template, :ambient, protocol_composition: [
          {"type" => "adapt", "count" => 1, "health" => 30, "max_health" => 30, "charge_rounds" => 0},
          {"type" => "trace", "count" => 1, "health" => 50, "max_health" => 50, "charge_rounds" => 0}
        ])
      end

      it "prevents ADAPT from mutating on ambient tier without 3+ TRACE" do
        breach = start_breach!(template: template)
        adapt_protocol = breach.grid_breach_protocols.find_by(protocol_type: "adapt")

        # Simulate 3 rounds of ADAPT ticking
        3.times do
          Grid::BreachProtocol::Engine.tick!(adapt_protocol, breach)
          adapt_protocol.reload
        end

        # Should NOT have mutated any protocol (only 1 TRACE, need 3)
        other = breach.grid_breach_protocols.find_by(protocol_type: "trace")
        expect(other.meta["adapted"]).to be_nil
      end
    end
  end

  describe "Reroute Command" do
    it "delays a protocol for one round" do
      breach = start_breach!
      protocol = breach.grid_breach_protocols.alive.first

      result = Grid::BreachActionService.reroute!(hackr: hackr, target_position: protocol.position)

      protocol.reload
      expect(protocol.rerouted?).to be true
      expect(result).to be_a(Grid::BreachActionService::RerouteResult)
    end

    it "costs one action" do
      breach = start_breach!
      protocol = breach.grid_breach_protocols.alive.first
      old_actions = breach.actions_remaining

      Grid::BreachActionService.reroute!(hackr: hackr, target_position: protocol.position)
      breach.reload

      expect(breach.actions_remaining).to eq(old_actions - 1)
    end

    it "raises AlreadyRerouted if protocol is already rerouted" do
      breach = start_breach!
      # Bump actions to allow multiple reroutes
      breach.update!(actions_this_round: 3, actions_remaining: 3)
      protocol = breach.grid_breach_protocols.alive.first

      Grid::BreachActionService.reroute!(hackr: hackr, target_position: protocol.position)

      expect {
        Grid::BreachActionService.reroute!(hackr: hackr, target_position: protocol.position)
      }.to raise_error(Grid::BreachActionService::AlreadyRerouted)
    end

    it "fizzle check: protocol fizzles when rand < 0.30" do
      breach = start_breach!
      protocol = breach.grid_breach_protocols.alive.where(protocol_type: "trace").first
      protocol.update_columns(meta: {"fizzle_check" => true})

      allow(Grid::BreachProtocol::Engine).to receive(:rand).and_return(0.1) # < 0.30 = fizzle
      messages = Grid::BreachProtocol::Engine.tick!(protocol, breach)
      protocol.reload

      expect(messages.first).to include("fizzled")
      expect(protocol.meta["fizzle_check"]).to be_nil
    end

    it "fizzle check: protocol fires normally when rand >= 0.30" do
      breach = start_breach!
      protocol = breach.grid_breach_protocols.alive.where(protocol_type: "trace").first
      protocol.update_columns(meta: {"fizzle_check" => true})

      allow(Grid::BreachProtocol::Engine).to receive(:rand).and_return(0.5) # >= 0.30 = fire
      messages = Grid::BreachProtocol::Engine.tick!(protocol, breach)
      protocol.reload

      expect(messages.first).to include("TRACE")
      expect(messages.first).to include("cycling")
      expect(protocol.meta["fizzle_check"]).to be_nil
    end

    it "protocol skips tick when rerouted, then has fizzle check" do
      breach = start_breach!
      protocol = breach.grid_breach_protocols.alive.where(protocol_type: "trace").first
      protocol.update_columns(rerouted: true)

      # Tick should skip and set fizzle_check
      messages = Grid::BreachProtocol::Engine.tick!(protocol, breach)
      protocol.reload

      expect(protocol.rerouted?).to be false
      expect(protocol.meta["fizzle_check"]).to be true
      expect(messages.first).to include("REROUTED")
    end
  end

  describe "Vitals-at-Zero: HEALTH 0" do
    let(:hospital_room) { create(:grid_room, grid_zone: zone, room_type: "hospital", slug: "test-restorepoint") }
    let(:template) do
      create(:grid_breach_template, protocol_composition: [
        {"type" => "spike", "count" => 1, "health" => 100, "max_health" => 100, "charge_rounds" => 0}
      ])
    end

    before do
      region.update!(hospital_room: hospital_room)
    end

    it "forces failure and admits to RestorePoint when HEALTH drops to 0" do
      hackr.set_stat!("health", 5) # Will drop to 0 on first SPIKE tick (6 damage)
      breach = start_breach!(template: template)

      breach.update!(actions_remaining: 0)
      result = Grid::BreachService.end_round!(hackr_breach: breach)

      breach.reload
      hackr.reload

      expect(breach.state).to eq("failure")
      expect(hackr.stat("health")).to be > 0 # Restored by RestorePoint
      expect(hackr.current_room_id).to eq(hospital_room.id)
      expect(result.display).to include("RESTOREPOINT")
    end
  end

  describe "Break on Death" do
    let(:double_spike_template) do
      create(:grid_breach_template, protocol_composition: [
        {"type" => "spike", "count" => 2, "health" => 100, "max_health" => 100, "charge_rounds" => 0},
        {"type" => "feedback", "count" => 1, "health" => 100, "max_health" => 100, "charge_rounds" => 0}
      ])
    end

    it "stops ticking protocols after HEALTH reaches 0" do
      hackr.set_stat!("health", 5) # First SPIKE kills (6 damage), second should NOT fire
      breach = start_breach!(template: double_spike_template)
      old_energy = hackr.stat("energy")
      old_psyche = hackr.stat("psyche")

      # SPIKE×2 at positions 0,1 — FEEDBACK at position 2
      spike_protocols = breach.grid_breach_protocols.where(protocol_type: "spike").order(:position)
      feedback_protocol = breach.grid_breach_protocols.find_by(protocol_type: "feedback")

      breach.update!(actions_remaining: 0)
      Grid::BreachService.end_round!(hackr_breach: breach)

      hackr.reload
      # FEEDBACK should not have fired — energy and psyche should only be drained by failure (20 each), not FEEDBACK (4/4)
      expect(hackr.stat("health")).to be > 0 # Restored by failure path
      expect(hackr.stat("energy")).to eq(old_energy - 20)
      expect(hackr.stat("psyche")).to eq(old_psyche - 20)

      # Second SPIKE should still be alive (never got to fire, wasn't destroyed)
      spike_protocols.last.reload
      expect(spike_protocols.last.state).not_to eq("destroyed")
      expect(spike_protocols.last.health).to eq(spike_protocols.last.max_health)
    end
  end

  describe "Energy Degradation" do
    it "reduces damage at 0 energy to 0" do
      breach = start_breach!
      hackr.set_stat!("energy", 0)

      protocol = breach.grid_breach_protocols.alive.first
      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Test Program",
        target_position: protocol.position
      )

      expect(result.damage_dealt).to eq(0)
    end

    it "reduces damage below 50% energy (25-49%: 0.90x)" do
      breach = start_breach!
      hackr.set_stat!("energy", 40) # 40% of 100 max

      protocol = breach.grid_breach_protocols.alive.first
      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Test Program",
        target_position: protocol.position
      )

      # Base 20, at 40% energy: 0.90 multiplier = 18
      expect(result.damage_dealt).to eq(18)
    end

    it "reduces damage at 10-24% energy (0.75x)" do
      breach = start_breach!
      hackr.set_stat!("energy", 15) # 15% of 100 max

      protocol = breach.grid_breach_protocols.alive.first
      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Test Program",
        target_position: protocol.position
      )

      # Base 20, at 15% energy: 0.75 multiplier = 15
      expect(result.damage_dealt).to eq(15)
    end

    it "reduces damage below 10% energy (0.50x)" do
      breach = start_breach!
      hackr.set_stat!("energy", 5) # 5% of 100 max

      protocol = breach.grid_breach_protocols.alive.first
      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Test Program",
        target_position: protocol.position
      )

      # Base 20, at 5% energy: 0.50 multiplier = 10
      expect(result.damage_dealt).to eq(10)
    end

    it "deals full damage at 50%+ energy" do
      breach = start_breach!
      hackr.set_stat!("energy", 50) # exactly 50%

      protocol = breach.grid_breach_protocols.alive.first
      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Test Program",
        target_position: protocol.position
      )

      # Base 20, at 50% energy: 1.0 multiplier = 20
      expect(result.damage_dealt).to eq(20)
    end
  end

  describe "Psyche Degradation" do
    it "returns wrong info at 0 psyche" do
      breach = start_breach!
      hackr.set_stat!("psyche", 0)

      protocol = breach.grid_breach_protocols.alive.first

      # Run analyze multiple times — at 0 psyche, should always get wrong info
      wrong_count = 0
      10.times do
        # Reset analyze level for each test
        protocol.update!(meta: protocol.meta.merge("analyze_level" => 0))
        result = Grid::BreachActionService.analyze!(hackr: hackr, target_position: protocol.position)
        # Wrong info means reported type won't match actual type
        actual_type = protocol.type_label
        wrong_count += 1 unless result.info_revealed.include?(actual_type)
        # Restore action
        breach.reload
        breach.update!(actions_remaining: 1) unless breach.actions_remaining > 0
      end

      # At 0 psyche, should be wrong 100% of the time
      expect(wrong_count).to eq(10)
    end
  end

  describe "BreachCommandParser reroute" do
    it "routes reroute/rr command" do
      breach = start_breach!
      parser = Grid::BreachCommandParser.new(hackr, "reroute 1", breach)
      result = parser.execute

      expect(result[:output]).to include("REROUTE")
    end

    it "routes rr alias" do
      breach = start_breach!
      parser = Grid::BreachCommandParser.new(hackr, "rr 1", breach)
      result = parser.execute

      expect(result[:output]).to include("REROUTE")
    end

    it "shows reroute in help" do
      breach = start_breach!
      parser = Grid::BreachCommandParser.new(hackr, "help", breach)
      result = parser.execute

      expect(result[:output]).to include("reroute")
      expect(result[:output]).to include("rr=reroute")
    end
  end

  describe "BreachRenderer" do
    it "renders SPIKE protocol with correct color" do
      template = create(:grid_breach_template, protocol_composition: [
        {"type" => "spike", "count" => 1, "health" => 30, "max_health" => 30, "charge_rounds" => 0}
      ])
      breach = start_breach!(template: template)

      renderer = Grid::BreachRenderer.new(breach)
      output = renderer.render_full

      expect(output).to include("#dc2626") # SPIKE color
    end

    it "renders PURGE protocol with correct color" do
      template = create(:grid_breach_template, protocol_composition: [
        {"type" => "purge", "count" => 1, "health" => 30, "max_health" => 30, "charge_rounds" => 0}
      ])
      breach = start_breach!(template: template)

      renderer = Grid::BreachRenderer.new(breach)
      output = renderer.render_full

      expect(output).to include("#8b5cf6") # PURGE color
    end

    it "shows reward meter when PURGE degrades multiplier" do
      template = create(:grid_breach_template, protocol_composition: [
        {"type" => "purge", "count" => 1, "health" => 30, "max_health" => 30, "charge_rounds" => 0}
      ])
      breach = start_breach!(template: template)
      breach.update!(reward_multiplier: 0.81)

      renderer = Grid::BreachRenderer.new(breach)
      output = renderer.render_full

      expect(output).to include("REWARDS")
      expect(output).to include("81%")
    end

    it "shows [REROUTED] tag on rerouted protocol" do
      breach = start_breach!
      protocol = breach.grid_breach_protocols.alive.first
      protocol.update_columns(rerouted: true)

      renderer = Grid::BreachRenderer.new(breach)
      output = renderer.render_full

      expect(output).to include("REROUTED")
    end
  end
end

RSpec.describe Grid::DebtService do
  let(:hackr) { create(:grid_hackr) }
  let!(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }

  describe ".assess!" do
    it "pays from cache when funds available" do
      # Stub reload chain so balance works
      allow_any_instance_of(GridCache).to receive(:balance).and_return(200)
      allow(Grid::TransactionService).to receive(:burn!)

      result = Grid::DebtService.assess!(hackr: hackr, amount: 100, memo: "test")

      expect(result[:paid]).to eq(100)
      expect(result[:debt_incurred]).to eq(0)
    end

    it "incurs debt when cache has insufficient funds" do
      allow_any_instance_of(GridCache).to receive(:balance).and_return(30)
      allow(Grid::TransactionService).to receive(:burn!)

      result = Grid::DebtService.assess!(hackr: hackr, amount: 100, memo: "test")

      expect(result[:paid]).to eq(30)
      expect(result[:debt_incurred]).to eq(70)
      expect(hackr.stat("govcorp_debt")).to eq(70)
    end

    it "incurs full debt when no funds" do
      allow_any_instance_of(GridCache).to receive(:balance).and_return(0)

      result = Grid::DebtService.assess!(hackr: hackr, amount: 100, memo: "test")

      expect(result[:paid]).to eq(0)
      expect(result[:debt_incurred]).to eq(100)
      expect(hackr.stat("govcorp_debt")).to eq(100)
    end
  end

  describe ".garnish" do
    it "returns full amount when no debt" do
      result = Grid::DebtService.garnish(hackr: hackr, gross_amount: 100)

      expect(result[:net_amount]).to eq(100)
      expect(result[:garnished]).to eq(0)
    end

    it "garnishes 50% when hackr has debt" do
      hackr.set_stat!("govcorp_debt", 200)

      result = Grid::DebtService.garnish(hackr: hackr, gross_amount: 100)

      expect(result[:net_amount]).to eq(50)
      expect(result[:garnished]).to eq(50)
      expect(result[:remaining_debt]).to eq(150)
    end

    it "garnishes exact debt amount when 50% exceeds debt" do
      hackr.set_stat!("govcorp_debt", 10)

      result = Grid::DebtService.garnish(hackr: hackr, gross_amount: 100)

      expect(result[:net_amount]).to eq(90)
      expect(result[:garnished]).to eq(10)
      expect(result[:remaining_debt]).to eq(0)
    end
  end

  describe ".pay!" do
    it "pays debt from cache" do
      hackr.set_stat!("govcorp_debt", 100)
      allow_any_instance_of(GridCache).to receive(:balance).and_return(80)
      allow(Grid::TransactionService).to receive(:burn!)

      result = Grid::DebtService.pay!(hackr: hackr, amount: 80)

      expect(result[:paid]).to eq(80)
      expect(result[:remaining_debt]).to eq(20)
      expect(hackr.stat("govcorp_debt")).to eq(20)
    end

    it "pays full debt when cache has enough" do
      hackr.set_stat!("govcorp_debt", 50)
      allow_any_instance_of(GridCache).to receive(:balance).and_return(200)
      allow(Grid::TransactionService).to receive(:burn!)

      result = Grid::DebtService.pay!(hackr: hackr)

      expect(result[:paid]).to eq(50)
      expect(result[:remaining_debt]).to eq(0)
    end

    it "pays nothing when no debt exists" do
      result = Grid::DebtService.pay!(hackr: hackr)

      expect(result[:paid]).to eq(0)
      expect(result[:remaining_debt]).to eq(0)
    end

    it "caps payment at available balance" do
      hackr.set_stat!("govcorp_debt", 200)
      allow_any_instance_of(GridCache).to receive(:balance).and_return(30)
      allow(Grid::TransactionService).to receive(:burn!)

      result = Grid::DebtService.pay!(hackr: hackr)

      expect(result[:paid]).to eq(30)
      expect(result[:remaining_debt]).to eq(170)
    end

    it "raises InsufficientFunds when no active cache" do
      hackr.set_stat!("govcorp_debt", 100)
      allow(hackr).to receive(:default_cache).and_return(nil)

      expect {
        Grid::DebtService.pay!(hackr: hackr)
      }.to raise_error(Grid::DebtService::InsufficientFunds)
    end
  end
end

RSpec.describe Grid::RestorePointService do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hospital_zone) { create(:grid_zone, grid_region: region) }
  let(:hospital_room) { create(:grid_room, grid_zone: hospital_zone, room_type: "hospital", slug: "test-rp") }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  before do
    region.update!(hospital_room: hospital_room)
    hackr.set_stat!("health", 0)
  end

  describe ".admit!" do
    it "moves hackr to hospital room" do
      allow(Grid::DebtService).to receive(:assess!).and_return({paid: 50, debt_incurred: 0, total_debt: 0})

      Grid::RestorePointService.admit!(hackr)

      hackr.reload
      expect(hackr.current_room_id).to eq(hospital_room.id)
    end

    it "restores health to 25% of max" do
      allow(Grid::DebtService).to receive(:assess!).and_return({paid: 50, debt_incurred: 0, total_debt: 0})

      Grid::RestorePointService.admit!(hackr)

      hackr.reload
      expect(hackr.stat("health")).to eq(25) # 25% of 100 max
    end

    it "assesses CRED fee based on clearance" do
      hackr.set_stat!("clearance", 10)
      # Fee = 50 + (10 * 5) = 100
      expect(Grid::DebtService).to receive(:assess!).with(
        hackr: hackr,
        amount: 100,
        memo: "RestorePoint\u2122 recovery fee"
      ).and_return({paid: 100, debt_incurred: 0, total_debt: 0})

      Grid::RestorePointService.admit!(hackr)
    end

    it "renders RestorePoint display" do
      allow(Grid::DebtService).to receive(:assess!).and_return({paid: 50, debt_incurred: 0, total_debt: 0})

      result = Grid::RestorePointService.admit!(hackr)

      expect(result.display).to include("RESTOREPOINT")
      expect(result.display).to include("Recovery fee assessed")
    end

    it "renders debt warning when funds insufficient" do
      allow(Grid::DebtService).to receive(:assess!).and_return({paid: 20, debt_incurred: 30, total_debt: 30})

      result = Grid::RestorePointService.admit!(hackr)

      expect(result.display).to include("GovCorp debt")
      expect(result.display).to include("garnished")
    end
  end
end
