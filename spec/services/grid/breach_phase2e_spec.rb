# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BREACH Phase 2E: Failure + Puzzles" do
  let(:zone) { create(:grid_zone, danger_level: 5) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:deck_def) do
    create(:grid_item_definition, :gear,
      slug: "test-deck-2e",
      name: "Test Deck",
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
  end

  let!(:deck) do
    item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    item.update!(equipped_slot: "deck")
    item
  end

  let(:sw_def) do
    create(:grid_item_definition, slug: "test-sw-2e", name: "Test Software", item_type: "software",
      properties: {"software_category" => "offensive", "slot_cost" => 1, "battery_cost" => 10, "effect_magnitude" => 20})
  end

  # ═══════════════════════════════════════════════════════════════
  # FAILURE TIERS 3-4
  # ═══════════════════════════════════════════════════════════════

  describe "Failure Tier 3: DECK software wipe" do
    let(:template) { create(:grid_breach_template, tier: "standard") }
    let(:encounter) { create(:grid_breach_encounter, grid_breach_template: template, grid_room: room) }

    it "wipes loaded software on standard tier failure" do
      # Load software into DECK
      software = create(:grid_item, :in_inventory, grid_item_definition: sw_def, grid_hackr: hackr, item_type: "software")
      software.update!(deck_id: deck.id)
      expect(deck.loaded_software.count).to eq(1)

      result = Grid::BreachService.start!(hackr: hackr, encounter: encounter)
      breach = result.hackr_breach

      # Force detection to 100 and trigger failure
      failure_result = Grid::BreachService.resolve_failure!(hackr_breach: breach)

      expect(failure_result.software_wiped).to be true
      expect(failure_result.fried_level).to be_nil
      expect(deck.reload.loaded_software.count).to eq(0)
      expect(failure_result.display).to include("DECK OVERLOADED")
    end
  end

  describe "Failure Tier 4: DECK fried" do
    let(:template) { create(:grid_breach_template, tier: "advanced") }
    let(:encounter) { create(:grid_breach_encounter, grid_breach_template: template, grid_room: room) }

    it "fries DECK on advanced tier failure" do
      software = create(:grid_item, :in_inventory, grid_item_definition: sw_def, grid_hackr: hackr, item_type: "software")
      software.update!(deck_id: deck.id)

      result = Grid::BreachService.start!(hackr: hackr, encounter: encounter)
      breach = result.hackr_breach
      failure_result = Grid::BreachService.resolve_failure!(hackr_breach: breach)

      expect(failure_result.fried_level).to be_between(2, 3)
      expect(failure_result.software_wiped).to be true
      expect(deck.reload.deck_fried?).to be true
      expect(deck.deck_fried_level).to be_between(2, 3)
      expect(deck.loaded_software.count).to eq(0)
      expect(failure_result.display).to include("DECK FRIED")
    end

    it "fries DECK at level 5 on world_event tier" do
      we_template = create(:grid_breach_template, tier: "world_event")
      we_encounter = create(:grid_breach_encounter, grid_breach_template: we_template, grid_room: room)
      result = Grid::BreachService.start!(hackr: hackr, encounter: we_encounter)
      breach = result.hackr_breach
      failure_result = Grid::BreachService.resolve_failure!(hackr_breach: breach)

      expect(failure_result.fried_level).to eq(5)
      expect(deck.reload.deck_fried_level).to eq(5)
    end

    it "does not fry DECK on ambient tier failure" do
      amb_template = create(:grid_breach_template, :ambient)
      result = Grid::BreachService.start_ambient!(hackr: hackr, template: amb_template)
      breach = result.hackr_breach
      failure_result = Grid::BreachService.resolve_failure!(hackr_breach: breach)

      expect(failure_result.fried_level).to be_nil
      expect(failure_result.software_wiped).to be false
      expect(deck.reload.deck_fried?).to be false
    end
  end

  describe "DECK fried guards" do
    let(:template) { create(:grid_breach_template) }
    let(:encounter) { create(:grid_breach_encounter, grid_breach_template: template, grid_room: room) }

    before { deck.update!(properties: deck.properties.merge("fried_level" => 3)) }

    it "blocks start! with fried DECK" do
      expect {
        Grid::BreachService.start!(hackr: hackr, encounter: encounter)
      }.to raise_error(Grid::BreachService::DeckFried, /fried/)
    end

    it "blocks start_ambient! with fried DECK" do
      amb_template = create(:grid_breach_template, :ambient)
      expect {
        Grid::BreachService.start_ambient!(hackr: hackr, template: amb_template)
      }.to raise_error(Grid::BreachService::DeckFried, /fried/)
    end
  end

  describe "Ambient fried-DECK auto-fail" do
    let(:amb_template) { create(:grid_breach_template, :ambient) }

    before do
      deck.update!(properties: deck.properties.merge("fried_level" => 2))
      allow(GridBreachTemplate).to receive_message_chain(:published, :ambient, :where, :where, :to_a).and_return([amb_template])
    end

    it "auto-fails with tier 1 consequences when ambient triggers with fried DECK" do
      # Manually call the auto-fail path
      service = Grid::BreachGeneratorService.new(hackr, room)
      result = service.send(:auto_fail_fried_deck!, amb_template)

      expect(result).to be_a(Grid::BreachGeneratorService::AmbientResult)
      expect(result.display).to include("DECK is fried")
      expect(result.display).to include("Repair your DECK")
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # DECK REPAIR
  # ═══════════════════════════════════════════════════════════════

  describe Grid::DeckRepairService do
    let(:repair_room) { create(:grid_room, grid_zone: zone, room_type: "repair_service") }

    describe ".repair_cost" do
      it "scales with fried_level and DECK rarity" do
        deck.update!(properties: deck.properties.merge("fried_level" => 3))
        # Default rarity from factory is "common" → quality multiplier 2
        quality = Grid::DeckRepairService::RARITY_QUALITY.fetch(deck.rarity.to_s, 1)
        cost = described_class.repair_cost(deck)
        expect(cost).to eq(150 * 3 * quality)
      end
    end

    describe ".repair_at_npc!" do
      it "raises DeckNotFried when DECK is not fried" do
        hackr.update!(current_room: repair_room)
        expect {
          described_class.repair_at_npc!(hackr: hackr)
        }.to raise_error(Grid::DeckRepairService::DeckNotFried)
      end

      it "raises error when not at repair_service room" do
        deck.update!(properties: deck.properties.merge("fried_level" => 2))
        hackr.update!(current_room: room) # not a repair_service room
        expect {
          described_class.repair_at_npc!(hackr: hackr)
        }.to raise_error(StandardError, /repair service/)
      end

      it "raises NoDeckEquipped when no deck is equipped" do
        hackr.update!(current_room: repair_room)
        deck.update!(equipped_slot: nil)
        expect {
          described_class.repair_at_npc!(hackr: hackr)
        }.to raise_error(Grid::DeckRepairService::NoDeckEquipped)
      end

      it "repairs fried DECK and charges CRED" do
        deck.update!(properties: deck.properties.merge("fried_level" => 2))
        hackr.update!(current_room: repair_room)
        cost = described_class.repair_cost(deck)

        # Stub CRED balance and payment
        cache = instance_double("GridCache", balance: cost + 100, active?: true)
        allow(hackr).to receive(:default_cache).and_return(cache)
        allow(Grid::TransactionService).to receive(:burn!)
        allow(Grid::TransactionService).to receive(:recycle!)

        result = described_class.repair_at_npc!(hackr: hackr)

        expect(result.fried_level_cleared).to eq(2)
        expect(result.cred_paid).to eq(cost)
        expect(deck.reload.deck_fried?).to be false
        expect(result.display).to include("DECK REPAIR COMPLETE")
        expect(Grid::TransactionService).to have_received(:burn!)
        expect(Grid::TransactionService).to have_received(:recycle!)
      end
    end
  end

  describe "repair_deck item effect" do
    let(:kit_def) do
      create(:grid_item_definition, slug: "test-repair-kit", name: "Test Repair Kit", item_type: "consumable",
        properties: {"effect_type" => "repair_deck", "kit_level" => 3})
    end

    let(:kit) { create(:grid_item, :in_inventory, grid_item_definition: kit_def, grid_hackr: hackr, item_type: "consumable") }

    before { deck.update!(properties: deck.properties.merge("fried_level" => 2)) }

    it "clears fried_level when kit_level >= fried_level" do
      the_hackr = hackr
      applier = Object.new
      applier.extend(Grid::ItemEffectApplier)
      applier.define_singleton_method(:hackr) { the_hackr }
      applier.define_singleton_method(:h) { |t| ERB::Util.html_escape(t.to_s) }

      result = applier.apply_item_effect(kit)
      expect(result).to include("DECK repaired")
      expect(deck.reload.deck_fried?).to be false
    end

    it "rejects kit when kit_level < fried_level" do
      deck.update!(properties: deck.properties.merge("fried_level" => 5))
      the_hackr = hackr
      applier = Object.new
      applier.extend(Grid::ItemEffectApplier)
      applier.define_singleton_method(:hackr) { the_hackr }
      applier.define_singleton_method(:h) { |t| ERB::Util.html_escape(t.to_s) }

      result = applier.apply_item_effect(kit)
      expect(result).to include("insufficient")
      expect(deck.reload.deck_fried?).to be true
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # PUZZLE GENERATOR
  # ═══════════════════════════════════════════════════════════════

  describe Grid::PuzzleGeneratorService do
    let(:rng) { Random.new(42) }

    it "generates a sequence puzzle" do
      result = described_class.generate({"type" => "sequence", "difficulty" => 3}, rng)
      expect(result[:display_data]["type"]).to eq("sequence")
      expect(result[:display_data]["nodes"]).to be_an(Array)
      expect(result[:display_data]["nodes"].size).to eq(6)
      expect(result[:solution]).to be_a(String)
      expect(result[:solution].split.size).to eq(6)
    end

    it "generates a logic_gate puzzle" do
      result = described_class.generate({"type" => "logic_gate", "difficulty" => 2}, rng)
      expect(result[:display_data]["type"]).to eq("logic_gate")
      expect(result[:display_data]["gate_type"]).to be_a(String)
      expect(result[:display_data]["inputs"]).to be_an(Array)
      # Solution format: "GATE_TYPE:TARGET:INPUT_COUNT" for dynamic validation
      expect(result[:solution]).to match(/\A[A-Z]+:(HIGH|LOW):\d+\z/)
    end

    it "generates a circuit puzzle" do
      result = described_class.generate({"type" => "circuit", "difficulty" => 2}, rng)
      expect(result[:display_data]["type"]).to eq("circuit")
      expect(result[:display_data]["left_nodes"]).to be_an(Array)
      expect(result[:display_data]["right_nodes"]).to be_an(Array)
      expect(result[:solution]).to be_a(String)
    end

    it "generates a credential puzzle" do
      result = described_class.generate({"type" => "credential", "difficulty" => 3}, rng)
      expect(result[:display_data]["type"]).to eq("credential")
      expect(result[:display_data]["encrypted"]).to be_a(String)
      expect(result[:display_data]["cipher_hint"]).to be_a(String)
      expect(result[:solution]).to be_a(String)
    end

    it "is deterministic with same seed" do
      r1 = described_class.generate({"type" => "sequence", "difficulty" => 2}, Random.new(99))
      r2 = described_class.generate({"type" => "sequence", "difficulty" => 2}, Random.new(99))
      expect(r1[:solution]).to eq(r2[:solution])
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # PUZZLE INTEGRATION
  # ═══════════════════════════════════════════════════════════════

  describe "Puzzle gate generation in BreachService.start!" do
    let(:puzzle_template) do
      create(:grid_breach_template,
        protocol_composition: [],
        puzzle_gates: [
          {"id" => "A", "type" => "sequence", "difficulty" => 2, "depends_on" => nil},
          {"id" => "B", "type" => "credential", "difficulty" => 1, "depends_on" => "A"}
        ])
    end
    let(:puzzle_encounter) { create(:grid_breach_encounter, grid_breach_template: puzzle_template, grid_room: room) }

    it "generates puzzle state in meta" do
      result = Grid::BreachService.start!(hackr: hackr, encounter: puzzle_encounter)
      breach = result.hackr_breach

      ps = breach.meta["puzzle_state"]
      expect(ps).to be_present
      expect(ps["gates"]).to have_key("A")
      expect(ps["gates"]).to have_key("B")
      expect(ps["gates"]["A"]["state"]).to eq("active")
      expect(ps["gates"]["B"]["state"]).to eq("locked")
      expect(ps["gates"]["A"]["solution"]).to be_a(String)
      expect(ps["required_count"]).to be >= 1
    end

    it "bypasses gates when clearance is high" do
      hackr.set_stat!("clearance", 60) # bypass_count = 60/30 = 2
      result = Grid::BreachService.start!(hackr: hackr, encounter: puzzle_encounter)
      breach = result.hackr_breach

      ps = breach.meta["puzzle_state"]
      bypassed = ps["gates"].values.count { |g| g["state"] == "bypassed" }
      expect(bypassed).to be >= 1
      expect(ps["required_count"]).to eq(1)
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # INTERFACE ACTION
  # ═══════════════════════════════════════════════════════════════

  describe Grid::BreachActionService, ".interface!" do
    let(:puzzle_template) do
      create(:grid_breach_template,
        protocol_composition: [],
        puzzle_gates: [
          {"id" => "A", "type" => "sequence", "difficulty" => 1, "depends_on" => nil}
        ])
    end
    let(:puzzle_encounter) { create(:grid_breach_encounter, grid_breach_template: puzzle_template, grid_room: room) }

    let!(:breach) do
      result = Grid::BreachService.start!(hackr: hackr, encounter: puzzle_encounter)
      result.hackr_breach
    end

    it "solves a gate with correct answer" do
      solution = breach.meta["puzzle_state"]["gates"]["A"]["solution"]
      result = described_class.interface!(hackr: hackr, gate_id: "A", answer: solution)

      expect(result.correct).to be true
      expect(result.gate_state).to eq("solved")
      expect(result.feedback).to eq("ACCESS GRANTED")
    end

    it "decrements attempts on wrong answer" do
      result = described_class.interface!(hackr: hackr, gate_id: "A", answer: "WRONG ANSWER")

      expect(result.correct).to be false
      expect(result.gate_state).to eq("active")
      expect(result.attempts_remaining).to be < breach.meta["puzzle_state"]["gates"]["A"]["max_attempts"]
    end

    it "locks gate when all attempts exhausted" do
      max_attempts = breach.meta["puzzle_state"]["gates"]["A"]["max_attempts"]
      max_attempts.times do
        described_class.interface!(hackr: hackr, gate_id: "A", answer: "WRONG")
        breach.reload
        # Restore action
        breach.update!(actions_remaining: 1) if breach.actions_remaining <= 0
      end

      breach.reload
      expect(breach.meta["puzzle_state"]["gates"]["A"]["state"]).to eq("failed")
    end

    it "raises GateNotFound for invalid gate ID" do
      expect {
        described_class.interface!(hackr: hackr, gate_id: "Z", answer: "test")
      }.to raise_error(Grid::BreachActionService::GateNotFound)
    end

    it "raises NoActionsRemaining when no actions left" do
      breach.update!(actions_remaining: 0)
      expect {
        described_class.interface!(hackr: hackr, gate_id: "A", answer: "test")
      }.to raise_error(Grid::BreachActionService::NoActionsRemaining)
    end

    it "consumes one action" do
      initial = breach.actions_remaining
      solution = breach.meta["puzzle_state"]["gates"]["A"]["solution"]
      described_class.interface!(hackr: hackr, gate_id: "A", answer: solution)
      expect(breach.reload.actions_remaining).to eq(initial - 1)
    end

    it "logs the interface action" do
      solution = breach.meta["puzzle_state"]["gates"]["A"]["solution"]
      described_class.interface!(hackr: hackr, gate_id: "A", answer: solution)

      log = GridHackrBreachLog.last
      expect(log.action_type).to eq("interface")
      expect(log.result["gate_id"]).to eq("A")
      expect(log.result["correct"]).to be true
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # OR WIN CONDITION
  # ═══════════════════════════════════════════════════════════════

  describe "OR win condition" do
    let(:mixed_template) do
      create(:grid_breach_template,
        protocol_composition: [
          {"type" => "trace", "count" => 1, "health" => 10, "max_health" => 10, "charge_rounds" => 0}
        ],
        puzzle_gates: [
          {"id" => "A", "type" => "sequence", "difficulty" => 1, "depends_on" => nil}
        ])
    end
    let(:mixed_encounter) { create(:grid_breach_encounter, grid_breach_template: mixed_template, grid_room: room) }

    it "wins via puzzle gates even with protocols alive" do
      result = Grid::BreachService.start!(hackr: hackr, encounter: mixed_encounter)
      breach = result.hackr_breach

      solution = breach.meta["puzzle_state"]["gates"]["A"]["solution"]
      interface_result = Grid::BreachActionService.interface!(hackr: hackr, gate_id: "A", answer: solution)

      expect(interface_result.all_solved).to be true
      expect(breach.reload.breach_won?).to be true
    end

    it "wins via protocols even with gates unsolved" do
      result = Grid::BreachService.start!(hackr: hackr, encounter: mixed_encounter)
      breach = result.hackr_breach

      # Destroy all protocols
      breach.grid_breach_protocols.update_all(state: "destroyed", health: 0)
      expect(breach.reload.breach_won?).to be true
    end

    it "does not win when neither condition is met" do
      result = Grid::BreachService.start!(hackr: hackr, encounter: mixed_encounter)
      breach = result.hackr_breach

      expect(breach.breach_won?).to be false
    end

    it "triggers success via end_round! when gates are solved mid-round" do
      result = Grid::BreachService.start!(hackr: hackr, encounter: mixed_encounter)
      breach = result.hackr_breach

      # Solve the gate directly (simulating interface! already consumed the action)
      ps = breach.meta["puzzle_state"]
      ps["gates"]["A"]["state"] = "solved"
      ps["solved_count"] = 1
      breach.update!(meta: breach.meta.merge("puzzle_state" => ps), actions_remaining: 0)

      # end_round! should detect breach_won? and resolve success
      round_result = Grid::BreachService.end_round!(hackr_breach: breach)
      expect(round_result.state).to eq(:success)
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # RENDERER
  # ═══════════════════════════════════════════════════════════════

  describe Grid::BreachRenderer do
    let(:puzzle_template) do
      create(:grid_breach_template,
        protocol_composition: [],
        puzzle_gates: [
          {"id" => "A", "type" => "sequence", "difficulty" => 1, "depends_on" => nil}
        ])
    end
    let(:puzzle_encounter) { create(:grid_breach_encounter, grid_breach_template: puzzle_template, grid_room: room) }

    it "includes circumvention gates block when gates exist" do
      result = Grid::BreachService.start!(hackr: hackr, encounter: puzzle_encounter)
      breach = result.hackr_breach

      renderer = described_class.new(breach)
      output = renderer.render_full

      expect(output).to include("PROTOCOL CIRCUMVENTION GATES")
      expect(output).to include("[A]")
      expect(output).to include("Sequence")
    end

    it "omits circumvention gates block when no gates exist" do
      std_template = create(:grid_breach_template)
      std_encounter = create(:grid_breach_encounter, grid_breach_template: std_template, grid_room: room)
      result = Grid::BreachService.start!(hackr: hackr, encounter: std_encounter)
      breach = result.hackr_breach

      renderer = described_class.new(breach)
      output = renderer.render_full

      expect(output).not_to include("PROTOCOL CIRCUMVENTION GATES")
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # GRID ITEM HELPERS
  # ═══════════════════════════════════════════════════════════════

  describe "GridItem DECK fried helpers" do
    it "deck_fried? returns true when fried_level > 0" do
      deck.update!(properties: deck.properties.merge("fried_level" => 3))
      expect(deck.deck_fried?).to be true
    end

    it "deck_fried? returns false when fried_level is 0 or absent" do
      expect(deck.deck_fried?).to be false
    end

    it "deck_fried_level returns the fried_level value" do
      deck.update!(properties: deck.properties.merge("fried_level" => 4))
      expect(deck.deck_fried_level).to eq(4)
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # HACKR BREACH MODEL HELPERS
  # ═══════════════════════════════════════════════════════════════

  describe "GridHackrBreach helpers" do
    let(:template) { create(:grid_breach_template) }
    let(:encounter) { create(:grid_breach_encounter, grid_breach_template: template, grid_room: room) }

    it "puzzle_gates_exist? returns false when no puzzle state" do
      result = Grid::BreachService.start!(hackr: hackr, encounter: encounter)
      expect(result.hackr_breach.puzzle_gates_exist?).to be false
    end

    it "puzzle_gates_exist? returns true when puzzle state has gates" do
      puzzle_template = create(:grid_breach_template,
        protocol_composition: [],
        puzzle_gates: [{"id" => "A", "type" => "sequence", "difficulty" => 1, "depends_on" => nil}])
      puzzle_encounter = create(:grid_breach_encounter, grid_breach_template: puzzle_template, grid_room: room)
      result = Grid::BreachService.start!(hackr: hackr, encounter: puzzle_encounter)
      expect(result.hackr_breach.puzzle_gates_exist?).to be true
    end
  end
end
