# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BREACH Phase 2C — Item Systems" do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:deck_def) do
    create(:grid_item_definition, :gear,
      slug: "test-deck-2c",
      name: "Test Deck",
      properties: {"slot" => "deck", "slot_count" => 8, "battery_max" => 128, "battery_current" => 128, "module_slot_count" => 2, "effects" => {}})
  end

  let!(:deck) do
    item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    item.update!(equipped_slot: "deck")
    item
  end

  let(:software_def) do
    create(:grid_item_definition,
      slug: "test-sw-2c",
      name: "Test Program",
      item_type: "software",
      properties: {"software_category" => "offensive", "slot_cost" => 1, "battery_cost" => 10, "effect_type" => "damage", "effect_magnitude" => 30, "level" => 1})
  end

  let!(:software) do
    item = create(:grid_item, :in_inventory, grid_item_definition: software_def, grid_hackr: hackr)
    item.update!(deck_id: deck.id)
    item
  end

  let(:template) do
    create(:grid_breach_template, protocol_composition: [
      {"type" => "trace", "count" => 1, "health" => 30, "max_health" => 30, "charge_rounds" => 0}
    ])
  end

  def start_breach!(tmpl: nil)
    tmpl ||= template
    enc = create(:grid_breach_encounter, grid_breach_template: tmpl, grid_room: room)
    result = Grid::BreachService.start!(hackr: hackr, encounter: enc)
    result.hackr_breach
  end

  # ── In-Encounter Use Command ──────────────────────────────

  describe "in-encounter use <item>" do
    let(:medpatch_def) do
      create(:grid_item_definition,
        slug: "test-medpatch",
        name: "MedPatch",
        item_type: "consumable",
        properties: {"effect_type" => "heal", "amount" => 30})
    end

    it "uses consumable from inventory during BREACH" do
      create(:grid_item, :in_inventory, grid_item_definition: medpatch_def, grid_hackr: hackr)
      hackr.set_stat!("health", 50)

      breach = start_breach!
      result = Grid::BreachActionService.use_item!(hackr: hackr, item_name: "MedPatch")

      expect(result.item_name).to eq("MedPatch")
      expect(result.effect_output).to include("Health restored")
      expect(result.emergency_jackout).to be false

      breach.reload
      expect(breach.actions_remaining).to eq(0) # started with 1 action
    end

    it "consumes the item after use" do
      item = create(:grid_item, :in_inventory, grid_item_definition: medpatch_def, grid_hackr: hackr, quantity: 2)
      start_breach!

      Grid::BreachActionService.use_item!(hackr: hackr, item_name: "MedPatch")
      expect(item.reload.quantity).to eq(1)
    end

    it "destroys last-stack item" do
      item = create(:grid_item, :in_inventory, grid_item_definition: medpatch_def, grid_hackr: hackr, quantity: 1)
      start_breach!

      Grid::BreachActionService.use_item!(hackr: hackr, item_name: "MedPatch")
      expect { item.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises when no actions remaining" do
      create(:grid_item, :in_inventory, grid_item_definition: medpatch_def, grid_hackr: hackr)
      breach = start_breach!
      breach.update!(actions_remaining: 0)

      expect {
        Grid::BreachActionService.use_item!(hackr: hackr, item_name: "MedPatch")
      }.to raise_error(Grid::BreachActionService::NoActionsRemaining)
    end

    it "raises when item not found" do
      start_breach!

      expect {
        Grid::BreachActionService.use_item!(hackr: hackr, item_name: "Nonexistent")
      }.to raise_error(Grid::BreachActionService::ItemNotFound)
    end

    it "logs the use action" do
      create(:grid_item, :in_inventory, grid_item_definition: medpatch_def, grid_hackr: hackr)
      breach = start_breach!

      Grid::BreachActionService.use_item!(hackr: hackr, item_name: "MedPatch")
      log = breach.grid_hackr_breach_logs.last
      expect(log.action_type).to eq("use")
      expect(log.result["item_name"]).to eq("MedPatch")
    end
  end

  # ── Signal Flare ──────────────────────────────────────────

  describe "signal flare (detection reduction)" do
    let(:flare_def) do
      create(:grid_item_definition,
        slug: "test-signal-flare",
        name: "Signal Flare",
        item_type: "consumable",
        properties: {"effect_type" => "signal_flare", "amount" => 15})
    end

    it "reduces detection level during BREACH" do
      create(:grid_item, :in_inventory, grid_item_definition: flare_def, grid_hackr: hackr)
      breach = start_breach!
      breach.update!(detection_level: 40)

      result = Grid::BreachActionService.use_item!(hackr: hackr, item_name: "Signal Flare")
      expect(result.effect_output).to include("Detection reduced")

      breach.reload
      expect(breach.detection_level).to eq(25)
    end

    it "clamps detection at 0" do
      create(:grid_item, :in_inventory, grid_item_definition: flare_def, grid_hackr: hackr)
      breach = start_breach!
      breach.update!(detection_level: 5)

      Grid::BreachActionService.use_item!(hackr: hackr, item_name: "Signal Flare")
      breach.reload
      expect(breach.detection_level).to eq(0)
    end

    it "fizzles outside BREACH" do
      flare = create(:grid_item, :in_inventory, grid_item_definition: flare_def, grid_hackr: hackr)
      applier = Object.new.extend(Grid::ItemEffectApplier)
      applier.define_singleton_method(:hackr) { hackr }
      applier.define_singleton_method(:h) { |t| ERB::Util.html_escape(t.to_s) }

      result = applier.apply_item_effect(flare)
      expect(result).to include("no signal to disrupt")
    end
  end

  # ── Emergency Jack-Out ────────────────────────────────────

  describe "emergency jack-out chip" do
    let(:chip_def) do
      create(:grid_item_definition,
        slug: "test-emergency-jackout",
        name: "Emergency Jack-Out Chip",
        item_type: "consumable",
        properties: {"effect_type" => "emergency_jackout"})
    end

    it "returns emergency_jackout flag" do
      create(:grid_item, :in_inventory, grid_item_definition: chip_def, grid_hackr: hackr)
      breach = start_breach!
      breach.update!(detection_level: 80) # past PNR

      result = Grid::BreachActionService.use_item!(hackr: hackr, item_name: "Emergency Jack-Out Chip")
      expect(result.emergency_jackout).to be true
    end

    it "enables clean jackout past PNR" do
      create(:grid_item, :in_inventory, grid_item_definition: chip_def, grid_hackr: hackr)
      breach = start_breach!
      breach.update!(detection_level: 80, pnr_threshold: 75)

      Grid::BreachActionService.use_item!(hackr: hackr, item_name: "Emergency Jack-Out Chip")

      # Emergency jackout should be clean despite PNR
      result = Grid::BreachService.jackout!(hackr: hackr, emergency: true)
      expect(result.clean).to be true
    end
  end

  # ── Exploit Instant-Kill ──────────────────────────────────

  describe "exploit mechanics" do
    let(:exploit_def) do
      create(:grid_item_definition,
        slug: "test-exploit-trace",
        name: "Trace Purge",
        item_type: "software",
        properties: {
          "software_category" => "exploit",
          "slot_cost" => 1,
          "battery_cost" => 16,
          "target_types" => ["trace"],
          "effect_type" => "instant_kill",
          "effect_magnitude" => 999,
          "level" => 1
        })
    end

    let!(:exploit) do
      item = create(:grid_item, :in_inventory, grid_item_definition: exploit_def, grid_hackr: hackr)
      item.update!(deck_id: deck.id)
      item
    end

    it "instantly kills matching protocol regardless of health" do
      tmpl = create(:grid_breach_template, protocol_composition: [
        {"type" => "trace", "count" => 1, "health" => 999, "max_health" => 999, "charge_rounds" => 0}
      ])
      breach = start_breach!(tmpl: tmpl)
      protocol = breach.grid_breach_protocols.first

      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Trace Purge",
        target_position: 0
      )

      expect(result.exploit).to be true
      expect(result.protocol_destroyed).to be true
      expect(result.damage_dealt).to eq(999)
      expect(protocol.reload.state).to eq("destroyed")
    end

    it "consumes exploit from DECK after successful use" do
      start_breach!

      Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Trace Purge",
        target_position: 0
      )

      expect { exploit.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "blocks execution against mismatched protocol type without consuming action" do
      tmpl = create(:grid_breach_template, protocol_composition: [
        {"type" => "lock", "count" => 1, "health" => 30, "max_health" => 30, "charge_rounds" => 0}
      ])
      breach = start_breach!(tmpl: tmpl)
      actions_before = breach.actions_remaining

      expect {
        Grid::BreachActionService.exec!(
          hackr: hackr,
          program_name: "Trace Purge",
          target_position: 0
        )
      }.to raise_error(Grid::BreachActionService::InvalidTarget, /incompatible/)

      breach.reload
      expect(breach.actions_remaining).to eq(actions_before) # action NOT consumed
      expect(exploit.reload).to be_present # exploit NOT destroyed
    end
  end

  # ── Utility Fragment Extraction ────────────────────────────

  describe "utility fragment extraction" do
    let(:utility_def) do
      create(:grid_item_definition,
        slug: "test-utility-extractor",
        name: "Fragment Extractor",
        item_type: "software",
        properties: {
          "software_category" => "utility",
          "slot_cost" => 1,
          "battery_cost" => 10,
          "effect_type" => "damage",
          "effect_magnitude" => 15,
          "fragment_chance" => 1.0,
          "level" => 1
        })
    end

    let!(:utility) do
      item = create(:grid_item, :in_inventory, grid_item_definition: utility_def, grid_hackr: hackr)
      item.update!(deck_id: deck.id)
      item
    end

    it "stores pending fragment on breach meta when roll succeeds" do
      breach = start_breach!

      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Fragment Extractor",
        target_position: 0
      )

      expect(result.fragment).to eq("trace-fragment")
      breach.reload
      expect(breach.meta["pending_fragments"]).to include("trace-fragment")
    end

    it "does not extract fragment when chance is 0" do
      utility_def.update!(properties: utility_def.properties.merge("fragment_chance" => 0.0))
      utility.update!(properties: utility_def.properties.merge("fragment_chance" => 0.0))

      start_breach!

      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Fragment Extractor",
        target_position: 0
      )

      expect(result.fragment).to be_nil
    end

    it "accumulates multiple fragments across rounds" do
      tmpl = create(:grid_breach_template, protocol_composition: [
        {"type" => "trace", "count" => 1, "health" => 200, "max_health" => 200, "charge_rounds" => 0}
      ])
      breach = start_breach!(tmpl: tmpl)

      # First exec
      Grid::BreachActionService.exec!(hackr: hackr, program_name: "Fragment Extractor", target_position: 0)

      # End round to get more actions
      Grid::BreachService.end_round!(hackr_breach: breach)
      breach.reload

      # Second exec
      Grid::BreachActionService.exec!(hackr: hackr, program_name: "Fragment Extractor", target_position: 0)

      breach.reload
      expect(breach.meta["pending_fragments"].size).to eq(2)
    end

    context "fragment granting on success" do
      let(:fragment_def) do
        create(:grid_item_definition,
          slug: "trace-fragment",
          name: "TRACE Fragment",
          item_type: "data",
          rarity: "uncommon",
          max_stack: 16)
      end

      it "grants pending fragments to inventory on breach success" do
        fragment_def # ensure definition exists

        breach = start_breach!

        # Extract a fragment
        Grid::BreachActionService.exec!(hackr: hackr, program_name: "Fragment Extractor", target_position: 0)

        # Manually mark all protocols destroyed for success
        breach.grid_breach_protocols.update_all(state: "destroyed", health: 0)

        Grid::BreachService.resolve_success!(hackr_breach: breach)

        fragment_item = hackr.grid_items.joins(:grid_item_definition)
          .find_by(grid_item_definitions: {slug: "trace-fragment"})
        expect(fragment_item).to be_present
      end

      it "forfeits fragments on failure" do
        fragment_def

        breach = start_breach!
        Grid::BreachActionService.exec!(hackr: hackr, program_name: "Fragment Extractor", target_position: 0)

        breach.reload
        expect(breach.meta["pending_fragments"]).to be_present

        # Force failure
        breach.update!(detection_level: 100)
        Grid::BreachService.resolve_failure!(hackr_breach: breach)

        fragment_item = hackr.grid_items.joins(:grid_item_definition)
          .find_by(grid_item_definitions: {slug: "trace-fragment"})
        expect(fragment_item).to be_nil
      end

      it "forfeits fragments on jackout" do
        fragment_def

        start_breach!
        Grid::BreachActionService.exec!(hackr: hackr, program_name: "Fragment Extractor", target_position: 0)

        Grid::BreachService.jackout!(hackr: hackr)

        fragment_item = hackr.grid_items.joins(:grid_item_definition)
          .find_by(grid_item_definitions: {slug: "trace-fragment"})
        expect(fragment_item).to be_nil
      end
    end
  end

  # ── Module & Firmware System ───────────────────────────────

  describe "module and firmware system" do
    let(:module_def) do
      create(:grid_item_definition,
        slug: "test-module",
        name: "Test Module",
        item_type: "module",
        rarity: "uncommon",
        properties: {"flashed" => false})
    end

    let(:firmware_def) do
      create(:grid_item_definition,
        slug: "test-firmware",
        name: "Test Firmware",
        item_type: "firmware",
        rarity: "uncommon",
        value: 100,
        properties: {"compatible_modules" => ["test-module"]})
    end

    it "allows module items to be created" do
      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr)
      expect(mod.deck_module?).to be true
      expect(mod.item_type).to eq("module")
    end

    it "allows flashed modules to be installed in DECK" do
      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "test-firmware"})

      mod.update!(deck_id: deck.id)
      expect(deck.installed_modules.count).to eq(1)
      expect(deck.deck_modules_used).to eq(1)
      expect(deck.deck_modules_available).to eq(1) # 2 slots - 1 used
    end

    it "checks module presence via has_module?" do
      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "test-firmware"})
      mod.update!(deck_id: deck.id)

      expect(deck.has_module?("test-module")).to be true
      expect(deck.has_module?("nonexistent")).to be false
    end

    it "enforces requires_module gate on software exec" do
      gated_sw_def = create(:grid_item_definition,
        slug: "test-gated-sw",
        name: "Gated Program",
        item_type: "software",
        properties: {
          "software_category" => "offensive",
          "slot_cost" => 1,
          "battery_cost" => 10,
          "effect_type" => "damage",
          "effect_magnitude" => 20,
          "requires_module" => "test-module",
          "level" => 1
        })

      gated_sw = create(:grid_item, :in_inventory, grid_item_definition: gated_sw_def, grid_hackr: hackr)
      gated_sw.update!(deck_id: deck.id)

      start_breach!

      expect {
        Grid::BreachActionService.exec!(
          hackr: hackr,
          program_name: "Gated Program",
          target_position: 0
        )
      }.to raise_error(Grid::BreachActionService::ProgramNotLoaded, /requires module/)
    end

    it "allows exec when required module is installed" do
      gated_sw_def = create(:grid_item_definition,
        slug: "test-gated-sw-2",
        name: "Gated Program 2",
        item_type: "software",
        properties: {
          "software_category" => "offensive",
          "slot_cost" => 1,
          "battery_cost" => 10,
          "effect_type" => "damage",
          "effect_magnitude" => 30,
          "requires_module" => "test-module",
          "level" => 1
        })

      gated_sw = create(:grid_item, :in_inventory, grid_item_definition: gated_sw_def, grid_hackr: hackr)
      gated_sw.update!(deck_id: deck.id)

      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "test-firmware"})
      mod.update!(deck_id: deck.id)

      start_breach!

      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: "Gated Program 2",
        target_position: 0
      )

      expect(result.hit).to be true
    end
  end

  # ── ItemEffectApplier Module ───────────────────────────────

  describe "ItemEffectApplier" do
    it "handles deck_recharge effect" do
      recharge_def = create(:grid_item_definition,
        slug: "test-power-bank",
        name: "Power Bank",
        item_type: "consumable",
        properties: {"effect_type" => "deck_recharge", "amount" => 32})

      create(:grid_item, :in_inventory, grid_item_definition: recharge_def, grid_hackr: hackr)
      deck.update!(properties: deck.properties.merge("battery_current" => 50))

      start_breach!
      Grid::BreachActionService.use_item!(hackr: hackr, item_name: "Power Bank")

      deck.reload
      expect(deck.deck_battery).to eq(82)
    end

    it "handles inspire effect during BREACH" do
      inspire_def = create(:grid_item_definition,
        slug: "test-muse-chip",
        name: "Muse Chip",
        item_type: "consumable",
        properties: {"effect_type" => "inspire", "amount" => 5})

      create(:grid_item, :in_inventory, grid_item_definition: inspire_def, grid_hackr: hackr)

      breach = start_breach!
      result = Grid::BreachActionService.use_item!(hackr: hackr, item_name: "Muse Chip")

      expect(result.effect_output).to include("INSPIRATION")
      breach.reload
      expect(breach.inspiration).to be > 0
    end
  end

  # ── BreachCommandParser Integration ────────────────────────

  describe "BreachCommandParser" do
    it "routes use command" do
      medpatch_def = create(:grid_item_definition,
        slug: "test-medpatch-cmd",
        name: "MedPatch",
        item_type: "consumable",
        properties: {"effect_type" => "heal", "amount" => 30})

      create(:grid_item, :in_inventory, grid_item_definition: medpatch_def, grid_hackr: hackr)
      hackr.set_stat!("health", 50)

      breach = start_breach!
      parser = Grid::BreachCommandParser.new(hackr, "use MedPatch", breach)
      result = parser.execute

      expect(result[:output]).to include("Health restored")
    end

    it "shows exploit kill message" do
      exploit_def = create(:grid_item_definition,
        slug: "test-exploit-cmd",
        name: "Test Exploit",
        item_type: "software",
        properties: {
          "software_category" => "exploit",
          "slot_cost" => 1,
          "battery_cost" => 10,
          "target_types" => ["trace"],
          "effect_type" => "instant_kill",
          "effect_magnitude" => 999,
          "level" => 1
        })

      exploit = create(:grid_item, :in_inventory, grid_item_definition: exploit_def, grid_hackr: hackr)
      exploit.update!(deck_id: deck.id)

      breach = start_breach!
      parser = Grid::BreachCommandParser.new(hackr, "exec Test Exploit 1", breach)
      result = parser.execute

      expect(result[:output]).to include("EXPLOIT")
      expect(result[:output]).to include("INSTANT KILL")
    end

    it "shows fragment extraction in exec output" do
      utility_def = create(:grid_item_definition,
        slug: "test-utility-cmd",
        name: "Test Utility",
        item_type: "software",
        properties: {
          "software_category" => "utility",
          "slot_cost" => 1,
          "battery_cost" => 10,
          "effect_type" => "damage",
          "effect_magnitude" => 15,
          "fragment_chance" => 1.0,
          "level" => 1
        })

      util = create(:grid_item, :in_inventory, grid_item_definition: utility_def, grid_hackr: hackr)
      util.update!(deck_id: deck.id)

      breach = start_breach!
      parser = Grid::BreachCommandParser.new(hackr, "exec Test Utility 1", breach)
      result = parser.execute

      expect(result[:output]).to include("Fragment extracted")
    end

    it "includes use in help output" do
      breach = start_breach!
      parser = Grid::BreachCommandParser.new(hackr, "help", breach)
      result = parser.execute

      expect(result[:output]).to include("use")
      expect(result[:output]).to include("consumable")
    end
  end

  # ── Deck Module Commands (CommandParser) ────────────────────

  describe "deck install command" do
    let(:module_def) do
      create(:grid_item_definition,
        slug: "test-install-mod",
        name: "Test Module",
        item_type: "module",
        rarity: "uncommon",
        properties: {"flashed" => false})
    end

    it "installs a flashed module into DECK" do
      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "some-fw"})

      parser = Grid::CommandParser.new(hackr, "deck install Test Module")
      result = parser.execute

      expect(result[:output]).to include("Installed")
      expect(mod.reload.deck_id).to eq(deck.id)
    end

    it "rejects unflashed module" do
      create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr)

      parser = Grid::CommandParser.new(hackr, "deck install Test Module")
      result = parser.execute

      expect(result[:output]).to include("no firmware")
    end

    it "rejects when module slots full" do
      # Fill both module slots
      2.times do |i|
        fill_def = create(:grid_item_definition,
          slug: "fill-mod-#{i}",
          name: "Fill Mod #{i}",
          item_type: "module",
          rarity: "common",
          properties: {"flashed" => true})
        fill = create(:grid_item, :in_inventory, grid_item_definition: fill_def, grid_hackr: hackr,
          properties: {"flashed" => true})
        fill.update!(deck_id: deck.id)
      end

      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "some-fw"})

      parser = Grid::CommandParser.new(hackr, "deck install Test Module")
      result = parser.execute

      expect(result[:output]).to include("No module slots")
      expect(mod.reload.deck_id).to be_nil
    end

    it "blocks install during BREACH (routes to BREACH deck view)" do
      create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "some-fw"})

      breach = start_breach!

      # During BREACH, all commands route through BreachCommandParser
      # "deck install ..." shows deck view (no subcommand routing)
      parser = Grid::BreachCommandParser.new(hackr, "deck install Test Module", breach)
      result = parser.execute

      expect(result[:output]).to include("DECK")
      expect(result[:output]).not_to include("Installed")
    end
  end

  describe "deck uninstall command" do
    let(:module_def) do
      create(:grid_item_definition,
        slug: "test-uninstall-mod",
        name: "Installed Module",
        item_type: "module",
        rarity: "uncommon",
        properties: {"flashed" => true, "firmware_slug" => "some-fw"})
    end

    it "uninstalls a module from DECK" do
      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "some-fw"})
      mod.update!(deck_id: deck.id)

      parser = Grid::CommandParser.new(hackr, "deck uninstall Installed Module")
      result = parser.execute

      expect(result[:output]).to include("Uninstalled")
      expect(mod.reload.deck_id).to be_nil
    end

    it "blocks uninstall during BREACH (routes to BREACH deck view)" do
      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "some-fw"})
      mod.update!(deck_id: deck.id)

      breach = start_breach!

      parser = Grid::BreachCommandParser.new(hackr, "deck uninstall Installed Module", breach)
      result = parser.execute

      expect(result[:output]).to include("DECK")
      expect(result[:output]).not_to include("Uninstalled")
      expect(mod.reload.deck_id).to eq(deck.id) # still installed
    end
  end

  describe "deck flash command" do
    let(:module_def) do
      create(:grid_item_definition,
        slug: "test-flash-mod",
        name: "Raw Module",
        item_type: "module",
        rarity: "uncommon",
        properties: {"flashed" => false})
    end

    let(:firmware_def) do
      create(:grid_item_definition,
        slug: "test-flash-fw",
        name: "Test Firmware",
        item_type: "firmware",
        rarity: "uncommon",
        value: 100,
        properties: {"compatible_modules" => ["test-flash-mod"]})
    end

    let(:flasher_def) do
      create(:grid_item_definition,
        slug: "eeprom-flasher",
        name: "EEPROM Flasher",
        item_type: "tool",
        rarity: "rare",
        max_stack: 1,
        properties: {})
    end

    context "DIY path (EEPROM Flasher in inventory)" do
      it "flashes firmware onto module, consuming firmware" do
        mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr)
        fw = create(:grid_item, :in_inventory, grid_item_definition: firmware_def, grid_hackr: hackr)
        create(:grid_item, :in_inventory, grid_item_definition: flasher_def, grid_hackr: hackr)

        parser = Grid::CommandParser.new(hackr, "deck flash Test Firmware onto Raw Module")
        result = parser.execute

        expect(result[:output]).to include("Firmware flashed")
        mod.reload
        expect(mod.properties["flashed"]).to be true
        expect(mod.properties["firmware_slug"]).to eq("test-flash-fw")
        expect { fw.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "decrements firmware quantity when stacked" do
        create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr)
        fw = create(:grid_item, :in_inventory, grid_item_definition: firmware_def, grid_hackr: hackr, quantity: 3)
        create(:grid_item, :in_inventory, grid_item_definition: flasher_def, grid_hackr: hackr)

        parser = Grid::CommandParser.new(hackr, "deck flash Test Firmware onto Raw Module")
        parser.execute

        expect(fw.reload.quantity).to eq(2)
      end

      it "rejects incompatible firmware" do
        create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr)
        incompat_def = create(:grid_item_definition,
          slug: "test-incompat-fw",
          name: "Wrong Firmware",
          item_type: "firmware",
          rarity: "uncommon",
          properties: {"compatible_modules" => ["other-module"]})
        create(:grid_item, :in_inventory, grid_item_definition: incompat_def, grid_hackr: hackr)
        create(:grid_item, :in_inventory, grid_item_definition: flasher_def, grid_hackr: hackr)

        parser = Grid::CommandParser.new(hackr, "deck flash Wrong Firmware onto Raw Module")
        result = parser.execute

        expect(result[:output]).to include("not compatible")
      end

      it "rejects without flasher tool or vendor room" do
        create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr)
        create(:grid_item, :in_inventory, grid_item_definition: firmware_def, grid_hackr: hackr)

        parser = Grid::CommandParser.new(hackr, "deck flash Test Firmware onto Raw Module")
        result = parser.execute

        expect(result[:output]).to include("EEPROM Flasher")
      end
    end

    context "vendor path (firmware_vendor room)" do
      let(:vendor_room) { create(:grid_room, grid_zone: zone, room_type: "firmware_vendor") }
      let(:hackr_cache) { create(:grid_cache, :default, grid_hackr: hackr) }
      let!(:burn_cache) { create(:grid_cache, :burn) }

      before do
        hackr.update!(current_room: vendor_room)
        hackr_cache
      end

      def fund_cache(target_cache, amount)
        source = create(:grid_cache)
        GridTransaction.create!(
          from_cache: source, to_cache: target_cache, amount: amount,
          tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
        )
      end

      it "buys and flashes firmware from vendor catalog" do
        firmware_def # ensure definition exists in DB
        mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr)
        fund_cache(hackr_cache, 500)

        parser = Grid::CommandParser.new(hackr, "deck flash Test Firmware onto Raw Module")
        result = parser.execute

        expect(result[:output]).to include("Firmware flashed")
        mod.reload
        expect(mod.properties["flashed"]).to be true
      end

      it "rejects when insufficient CRED" do
        firmware_def
        create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr)

        parser = Grid::CommandParser.new(hackr, "deck flash Test Firmware onto Raw Module")
        result = parser.execute

        expect(result[:output]).to include("Insufficient CRED")
      end
    end

    it "overwrites existing firmware with notification" do
      mod = create(:grid_item, :in_inventory, grid_item_definition: module_def, grid_hackr: hackr,
        properties: {"flashed" => true, "firmware_slug" => "old-firmware"})
      create(:grid_item, :in_inventory, grid_item_definition: firmware_def, grid_hackr: hackr)
      create(:grid_item, :in_inventory, grid_item_definition: flasher_def, grid_hackr: hackr)

      parser = Grid::CommandParser.new(hackr, "deck flash Test Firmware onto Raw Module")
      result = parser.execute

      expect(result[:output]).to include("Previous firmware overwritten")
      expect(mod.reload.properties["firmware_slug"]).to eq("test-flash-fw")
    end
  end
end
