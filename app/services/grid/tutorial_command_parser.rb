# frozen_string_literal: true

module Grid
  # Handles command dispatch during the Bootloader tutorial.
  # Sits in the CommandParser#execute priority chain after breach/captured/transit.
  # Delegates most commands to the main parser, wrapping output with tutorial chrome.
  class TutorialCommandParser
    BLOCKED_COMMANDS = %w[say drop].freeze

    # Commands only available during their relevant tutorial chapter steps
    GATED_COMMANDS = {
      %w[sell] => %w[sell-item],
      %w[fabricate fab] => %w[fabricate-item],
      %w[schematics schem sch schematic] => %w[check-schematics fabricate-item],
      %w[salvage sal] => %w[salvage-item],
      %w[buy purchase] => %w[buy-item sell-item],
      %w[shop browse] => %w[browse-shop buy-item sell-item]
    }.freeze

    # Commands that bypass tutorial hint injection (output passes through clean)
    PASSTHROUGH_COMMANDS = %w[clear cls cl].freeze

    attr_reader :hackr, :input, :parser

    # ─── Step Definitions ────────────────────────────────────────────
    # Each step: slug, chapter, narrative (shown on step activation),
    # hint (shown if hackr hasn't completed step yet), condition type + target,
    # and optional grants (items given when step activates).
    #
    # Condition types:
    #   :command_used   — hackr ran this command (matches first word)
    #   :in_room        — hackr is in room with this slug
    #   :has_item       — hackr has item with this definition slug
    #   :moved          — hackr moved to any room (event type == movement)
    #   :deck_not_fried — equipped deck is not fried
    #   :deck_has_software — equipped deck has loaded software
    #   :breach_completed  — hackr completed a breach with target template slug
    #   :rig_inactive   — mining rig is not active
    #   :rig_not_functional — mining rig is not functional
    #   :rig_functional — mining rig is functional
    #   :rig_active     — mining rig is active
    #   :choosing_start — hackr is choosing starting room (final step)

    STEPS = [
      # ═══ Chapter 1: BOOT SEQUENCE ═══
      {slug: "look-around", chapter: "BOOT SEQUENCE",
       narrative: "BOOTLOADER v4.7.2 // FRACTURE NETWORK TRAINING SIMULATION\n" \
                  "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
                  "Welcome, operative. You have been selected for orientation.\n" \
                  "This VR training environment will prepare you for THE PULSE GRID.\n" \
                  "Start by observing your environment.",
       hint: "Type <span style='color: #22d3ee;'>look</span> to observe your surroundings.",
       condition: {type: :command_used, match: %w[look l]}},

      {slug: "first-move", chapter: "BOOT SEQUENCE",
       narrative: "Good. You can see the room layout, exits, NPCs, and items.\n" \
                  "Now try moving — pick any exit direction.",
       hint: "Move to another room. Type a direction like <span style='color: #22d3ee;'>north</span> or <span style='color: #22d3ee;'>go north</span>.",
       condition: {type: :moved}},

      {slug: "find-locker", chapter: "BOOT SEQUENCE",
       narrative: "Navigation functional. Explore the hub area — find the Equipment Locker.\n" \
                  "Check the exits in each room to find your way.",
       hint: "Navigate to the Equipment Locker. It's east of the hub.",
       condition: {type: :in_room, target: "bl-equipment-locker"}},

      {slug: "take-item", chapter: "BOOT SEQUENCE",
       narrative: "Supply cache located. You notice a <span style='color: #22d3ee;'>Training Stim Pack</span> on the floor.\n" \
                  "Items on the floor can be picked up.",
       hint: "Type <span style='color: #22d3ee;'>take Training Stim Pack</span> to pick up the item.",
       condition: {type: :has_item, target: "training-stim-pack"},
       ensure_floor_item: {slug: "training-stim-pack", room: "bl-equipment-locker"}},

      {slug: "check-inventory", chapter: "BOOT SEQUENCE",
       narrative: "Item acquired. Check your inventory to confirm what you're carrying.",
       hint: "Type <span style='color: #22d3ee;'>inv</span> to see your inventory.",
       condition: {type: :command_used, match: %w[inventory inv i]}},

      # ═══ Chapter 2: INTERFACE TRAINING ═══
      {slug: "use-item", chapter: "INTERFACE TRAINING",
       narrative: "Good — you can see everything you're carrying.\n" \
                  "Consumable items can restore vitals and provide other effects.",
       hint: "Type <span style='color: #22d3ee;'>use Training Stim Pack</span> to consume the item.",
       condition: {type: :not_has_item, target: "training-stim-pack"}},

      {slug: "find-guide", chapter: "INTERFACE TRAINING",
       narrative: "Effect applied. Now proceed to the Interface Chamber for NPC interaction training.\n" \
                  "An instructor is waiting.",
       hint: "Navigate to the Interface Chamber — south from the hub.",
       condition: {type: :in_room, target: "bl-interface-chamber"}},

      {slug: "talk-npc", chapter: "INTERFACE TRAINING",
       narrative: "You see AXIOM, your training coordinator. Interact with them.",
       hint: "Type <span style='color: #22d3ee;'>talk AXIOM</span> to speak with the instructor.",
       condition: {type: :stat_positive, target: "npcs_talked"}},

      {slug: "ask-npc", chapter: "INTERFACE TRAINING",
       narrative: "NPCs have knowledge on various topics you can inquire about.",
       hint: "Type <span style='color: #22d3ee;'>ask AXIOM about training</span> to ask about a topic.",
       condition: {type: :dialogue_depth, target: 1}},

      {slug: "check-status", chapter: "INTERFACE TRAINING",
       narrative: "Good. You can always review your operational status — vitals, clearance, CRED, and more.",
       hint: "Type <span style='color: #22d3ee;'>stat</span> to see your current status.",
       condition: {type: :command_used, match: %w[stat stats st]}},

      {slug: "examine", chapter: "INTERFACE TRAINING",
       narrative: "Status confirmed. You can also examine items, NPCs, and equipment in detail.",
       hint: "Type <span style='color: #22d3ee;'>examine AXIOM</span> or examine any item.",
       condition: {type: :command_used, match: %w[examine ex x]}},

      # ═══ Chapter 3: DECK OPERATIONS ═══
      {slug: "find-deck-lab", chapter: "DECK OPERATIONS",
       narrative: "Interface protocols confirmed. Proceed to the DECK Lab for equipment issue.",
       hint: "Navigate to the DECK Lab — south from the Interface Chamber.",
       condition: {type: :in_room, target: "bl-deck-lab"},
       grants: [{slug: "training-deck", fried_level: 1, equip: true}],
       grant_narrative: "<span style='color: #fbbf24;'>PATCH slides a battered DECK unit across the counter.</span>\n" \
                        "<span style='color: #d0d0d0;'>'This one took a hit during a failed BREACH. Fried — level 1 damage.\n" \
                        "A DECK is your primary tool for breaching network nodes.\n" \
                        "But this one won't work until you get it repaired. Check its status first.'</span>"},

      {slug: "check-deck", chapter: "DECK OPERATIONS",
       narrative: "You've been issued a DECK — but it's damaged from a prior BREACH failure.\n" \
                  "This is what happens when things go wrong. Check its status.",
       hint: "Type <span style='color: #22d3ee;'>deck</span> to see your DECK status.",
       condition: {type: :command_used, match: %w[deck dk]}},

      {slug: "find-repair", chapter: "DECK OPERATIONS",
       narrative: "DECK status: FRIED (level 1). Cannot initiate BREACH operations.\n" \
                  "In the Grid, you can repair at designated service points or use Repair Kits.\n" \
                  "The Repair Bay is east of here.",
       hint: "Navigate to the Repair Bay to repair your DECK.",
       condition: {type: :in_room, target: "bl-repair-bay"}},

      {slug: "repair-deck", chapter: "DECK OPERATIONS",
       narrative: "Repair Bay located. In the real Grid, repairs cost CRED.\n" \
                  "Training sim covers the cost. Type repair to fix your DECK.",
       hint: "Type <span style='color: #22d3ee;'>repair</span> to fix your DECK.",
       condition: {type: :deck_not_fried}},

      {slug: "return-deck-lab", chapter: "DECK OPERATIONS",
       narrative: "DECK operational! Head back to the DECK Lab for your software loadout.",
       hint: "Navigate back to the DECK Lab.",
       condition: {type: :in_room, target: "bl-deck-lab"},
       grants: [{slug: "training-probe"}, {slug: "training-shield"}],
       grant_narrative: "<span style='color: #fbbf24;'>PATCH sets two data chips onto the counter.</span>\n" \
                        "<span style='color: #d0d0d0;'>'These chips contain two different types of software.\n" \
                        "Offensive software damages protocols. Defensive software protects you.\n" \
                        "Load each one onto your DECK separately.'</span>"},

      {slug: "load-software", chapter: "DECK OPERATIONS",
       narrative: "Software issued. Load each piece onto your DECK individually to prepare for BREACH training.",
       hint: "Type <span style='color: #22d3ee;'>deck load Training Probe</span> then <span style='color: #22d3ee;'>deck load Training Shield</span> to load both.",
       condition: {type: :deck_software_count, target: 2}},

      # ═══ Chapter 4: BREACH TRAINING ═══
      {slug: "find-arena", chapter: "BREACH TRAINING",
       narrative: "DECK loaded and operational. Time for combat simulation.\n" \
                  "Head to the Arena Lobby — south from the DECK Lab.",
       hint: "Navigate to the Arena Lobby.",
       condition: {type: :in_room, target: "bl-arena-lobby"}},

      {slug: "breach-protocol", chapter: "BREACH TRAINING",
       narrative: "Three simulation chambers available.\n\n" \
                  "Start with <span style='color: #22d3ee;'>Simulation α</span> — a protocol-only BREACH.\n" \
                  "Protocols are hostile programs you must destroy using your software.\n" \
                  "Commands: <span style='color: #22d3ee;'>exec &lt;software&gt;</span> to attack, <span style='color: #22d3ee;'>analyze &lt;protocol&gt;</span> to identify weaknesses.\n" \
                  "Watch the detection meter — if it hits 100%, you fail.",
       hint: "Go <span style='color: #22d3ee;'>northeast</span> to Simulation α, then type <span style='color: #22d3ee;'>breach</span> to begin.",
       condition: {type: :breach_completed, target: "protocol-drill-alpha"}},

      {slug: "breach-pcg", chapter: "BREACH TRAINING",
       narrative: "Protocol BREACH cleared! Next: <span style='color: #22d3ee;'>Simulation β</span> — a puzzle circumvention gate (PCG) BREACH.\n" \
                  "Instead of protocols, you'll solve puzzle gates to win.\n" \
                  "Command: <span style='color: #22d3ee;'>interface &lt;answer&gt;</span> to attempt a gate solution.",
       hint: "Go to Simulation β (east from lobby), then <span style='color: #22d3ee;'>breach</span> to begin.",
       condition: {type: :breach_completed, target: "cipher-drill-beta"}},

      {slug: "breach-mixed", chapter: "BREACH TRAINING",
       narrative: "PCG solved! Final simulation: <span style='color: #22d3ee;'>Simulation γ</span> — a mixed BREACH.\n" \
                  "Both protocols AND puzzle gates. Destroy all protocols OR solve all gates to win.\n" \
                  "Two paths to victory — choose your approach.",
       hint: "Go to Simulation γ (southeast from lobby), then <span style='color: #22d3ee;'>breach</span> to begin.",
       condition: {type: :breach_completed, target: "combined-drill-gamma"}},

      {slug: "post-breach", chapter: "BREACH TRAINING",
       narrative: "All BREACH simulations cleared. After breaching, your DECK battery drains.\n" \
                  "Head to the Debrief Room for a Power Bank.",
       hint: "Go <span style='color: #22d3ee;'>south</span> from the Arena Lobby to the Debrief Room.",
       condition: {type: :in_room, target: "bl-arena-debrief"},
       grants: [{slug: "training-power-bank"}],
       grant_narrative: "<span style='color: #fbbf24;'>A supply crate contains a Power Bank.</span>\n" \
                        "<span style='color: #d0d0d0;'>'Power Banks recharge your DECK battery.\n" \
                        "If your battery runs out during a BREACH, you can't use software.\n" \
                        "Keep one in your inventory.'</span>"},

      {slug: "check-battery", chapter: "BREACH TRAINING",
       narrative: "Your DECK battery drains with every software execution during a BREACH.\n" \
                  "Check your DECK status to see where your battery stands.",
       hint: "Type <span style='color: #22d3ee;'>deck</span> to check your DECK battery level.",
       condition: {type: :command_used, match: %w[deck dk]}},

      {slug: "recharge-deck", chapter: "BREACH TRAINING",
       narrative: "See the battery level? Power Banks restore it. Use the one you just received.",
       hint: "Type <span style='color: #22d3ee;'>use Training Power Bank</span> to recharge your DECK.",
       condition: {type: :not_has_item, target: "training-power-bank"}},

      {slug: "verify-battery", chapter: "BREACH TRAINING",
       narrative: "Good. Check your DECK again to confirm the recharge.",
       hint: "Type <span style='color: #22d3ee;'>deck</span> to verify your battery was restored.",
       condition: {type: :command_used, match: %w[deck dk]}},

      # ═══ Chapter 5: SUPPLY CHAIN ═══
      {slug: "find-supply", chapter: "SUPPLY CHAIN",
       narrative: "Combat training complete. Time to learn the supply chain.\n" \
                  "Head to the Supply Depot.",
       hint: "Navigate to the Supply Depot — south from the Debrief Room.",
       condition: {type: :in_room, target: "bl-supply-depot"}},

      {slug: "browse-shop", chapter: "SUPPLY CHAIN",
       narrative: "VECTOR runs a supply cache here. In the Grid, vendors sell items for CRED.\n" \
                  "Training sim prices are zero — but real-world items cost CRED.\n" \
                  "You earn CRED by mining (your rig), completing missions, and salvaging.",
       hint: "Type <span style='color: #22d3ee;'>shop</span> to see what's for sale.",
       condition: {type: :command_used, match: %w[shop browse]}},

      {slug: "buy-item", chapter: "SUPPLY CHAIN",
       narrative: "Good. Try buying something.",
       hint: "Type <span style='color: #22d3ee;'>buy</span> followed by an item name to purchase it.",
       condition: {type: :flag, target: "tutorial_buy_succeeded"}},

      {slug: "sell-item", chapter: "SUPPLY CHAIN",
       narrative: "Item purchased. You can also sell items back to vendors.",
       hint: "Type <span style='color: #22d3ee;'>sell</span> followed by an item name to sell it.",
       condition: {type: :flag, target: "tutorial_sell_succeeded"}},

      {slug: "find-salvage", chapter: "SUPPLY CHAIN",
       narrative: "Buy/sell confirmed. Items can also be broken down into raw materials.\n" \
                  "Head to the Salvage Workshop.",
       hint: "Navigate to the Salvage Workshop — east from the Supply Depot.",
       condition: {type: :in_room, target: "bl-salvage-workshop"},
       grants: [{slug: "training-scrap", quantity: 2}],
       grant_narrative: "<span style='color: #fbbf24;'>Training materials issued:</span> <span style='color: #d0d0d0;'>2x Training Scrap</span>"},

      {slug: "salvage-item", chapter: "SUPPLY CHAIN",
       narrative: "Materials received. Salvaging breaks items into components.\n" \
                  "Tip: use <span style='color: #22d3ee;'>analyze &lt;item&gt;</span> first to preview what you'll get.",
       hint: "Type <span style='color: #22d3ee;'>salvage Training Scrap</span> to break it down.",
       condition: {type: :has_item, target: "training-alloy"}},

      {slug: "find-fabrication", chapter: "SUPPLY CHAIN",
       narrative: "Materials acquired from salvage. Now learn fabrication — crafting new items from materials.\n" \
                  "Head to the Fabrication Terminal.",
       hint: "Navigate to the Fabrication Terminal — east from the Salvage Workshop.",
       condition: {type: :in_room, target: "bl-fabrication-terminal"}},

      {slug: "check-schematics", chapter: "SUPPLY CHAIN",
       narrative: "Schematics are blueprints for crafting. Check what's available to build.",
       hint: "Type <span style='color: #22d3ee;'>schematics</span> to see available crafting recipes.",
       condition: {type: :command_used, match: %w[schematics schem sch]}},

      {slug: "fabricate-item", chapter: "SUPPLY CHAIN",
       narrative: "Schematics listed. You have the materials — try fabricating something.",
       hint: "Type <span style='color: #22d3ee;'>fabricate fab-training-tool-kit</span> to craft the Training Tool Kit.",
       condition: {type: :has_item, target: "training-tool-kit"}},

      # ═══ Chapter 6: TRANSIT OPERATIONS ═══
      {slug: "find-transit", chapter: "TRANSIT OPERATIONS",
       narrative: "Supply chain training complete.\n" \
                  "THE PULSE GRID spans multiple regions connected by transit networks.\n" \
                  "Head to the Transit Hub to learn public and private transit.",
       hint: "Navigate to the Transit Hub.",
       condition: {type: :in_room, target: "bl-transit-hub"}},

      {slug: "check-transit", chapter: "TRANSIT OPERATIONS",
       narrative: "Transit routes are displayed when you look around a transit stop.\n" \
                  "You can also check route info with the transit command.",
       hint: "Type <span style='color: #22d3ee;'>transit</span> to see transit options.",
       condition: {type: :command_used, match: %w[transit tr]}},

      {slug: "ride-public", chapter: "TRANSIT OPERATIONS",
       narrative: "Board the shuttle using its route slug. Once aboard:\n" \
                  "  <span style='color: #22d3ee;'>wait</span> — advance to next stop\n" \
                  "  <span style='color: #22d3ee;'>disembark</span> — exit at current stop\n" \
                  "Ride to the last stop — Relay Point B.",
       hint: "<span style='color: #22d3ee;'>board bootloader-shuttle</span> to board, then <span style='color: #22d3ee;'>wait</span> to ride through stops. Destination: Relay Point B.",
       condition: {type: :in_room, target: "bl-transit-stop-b"}},

      {slug: "hail-private", chapter: "TRANSIT OPERATIONS",
       narrative: "Public transit mastered! Private transit is point-to-point — pick a destination and arrive in one stop.\n" \
                  "Hail a Training Taxi to Relay Point C.",
       hint: "Type <span style='color: #22d3ee;'>hail training-taxi relay point c</span> to hail a taxi, then <span style='color: #22d3ee;'>wait</span> to arrive.",
       condition: {type: :in_room, target: "bl-transit-stop-c"}},

      # ═══ Chapter 7: SYSTEM CHECK ═══
      {slug: "find-systems", chapter: "SYSTEM CHECK",
       narrative: "Transit mastered. Final phase — system diagnostics.\n" \
                  "Head to the Systems Lab.",
       hint: "Navigate to the Systems Lab.",
       condition: {type: :in_room, target: "bl-systems-lab"}},

      {slug: "rig-status", chapter: "SYSTEM CHECK",
       narrative: "Your mining rig generates CRED passively while you're active on the Grid.\n" \
                  "It was provisioned during registration with basic components.\n" \
                  "Start by checking its status.",
       hint: "Type <span style='color: #22d3ee;'>rig</span> to see your mining rig status.",
       condition: {type: :command_used, match: %w[rig]}},

      {slug: "rig-inspect-detail", chapter: "SYSTEM CHECK",
       narrative: "That shows the overview. You can see a detailed component breakdown\n" \
                  "including slot types, multipliers, and what's installed where.",
       hint: "Type <span style='color: #22d3ee;'>rig inspect</span> for the detailed component view.",
       condition: {type: :command_used, match: %w[rig]}},

      {slug: "rig-ensure-off", chapter: "SYSTEM CHECK",
       narrative: "To install or remove components, the rig must be offline.\n" \
                  "In the Grid, rig modifications also require your den — here, the lab simulates that.\n" \
                  "Your rig may already be off. If it's active, deactivate it.",
       hint: "Type <span style='color: #22d3ee;'>rig off</span> to deactivate. If already off, type it anyway — it's safe.",
       condition: {type: :rig_inactive}},

      {slug: "rig-verify-off", chapter: "SYSTEM CHECK",
       narrative: "Good. Confirm the rig is offline.",
       hint: "Type <span style='color: #22d3ee;'>rig</span> to verify the rig is offline.",
       condition: {type: :command_used, match: %w[rig]}},

      {slug: "rig-uninstall", chapter: "SYSTEM CHECK",
       narrative: "Rig is offline and ready for modifications.\n" \
                  "Let's remove a component to see what happens. The GPU handles mining calculations.",
       hint: "Type <span style='color: #22d3ee;'>rig uninstall Basic GPU</span> to remove the GPU.",
       condition: {type: :rig_not_functional}},

      {slug: "rig-check-inv", chapter: "SYSTEM CHECK",
       narrative: "GPU removed. The component is now in your inventory — not lost, just uninstalled.\n" \
                  "Check your inventory to confirm.",
       hint: "Type <span style='color: #22d3ee;'>inv</span> to see the GPU in your inventory.",
       condition: {type: :command_used, match: %w[inventory inv i]}},

      {slug: "rig-inspect-broken", chapter: "SYSTEM CHECK",
       narrative: "There it is. Now check the rig — notice the missing component.",
       hint: "Type <span style='color: #22d3ee;'>rig inspect</span> to see the gap in your rig.",
       condition: {type: :command_used, match: %w[rig]}},

      {slug: "rig-try-start", chapter: "SYSTEM CHECK",
       narrative: "See the empty GPU slot? A rig needs all core components to function:\n" \
                  "motherboard, PSU, CPU, GPU, and RAM. Try starting it anyway.",
       hint: "Type <span style='color: #22d3ee;'>rig on</span> to attempt activation.",
       condition: {type: :command_used, match: %w[rig]}},

      {slug: "rig-reinstall", chapter: "SYSTEM CHECK",
       narrative: "Won't start — missing components. Reinstall the GPU from your inventory.",
       hint: "Type <span style='color: #22d3ee;'>rig install Basic GPU</span> to reinstall it.",
       condition: {type: :rig_functional}},

      {slug: "rig-start", chapter: "SYSTEM CHECK",
       narrative: "Rig functional again — all slots filled. Now activate it.",
       hint: "Type <span style='color: #22d3ee;'>rig on</span> to start mining.",
       condition: {type: :rig_active}},

      {slug: "rig-final-inspect", chapter: "SYSTEM CHECK",
       narrative: "Rig is online and mining. Do a final inspection to confirm everything is working.",
       hint: "Type <span style='color: #22d3ee;'>rig inspect</span> to verify all components are active.",
       condition: {type: :command_used, match: %w[rig]}},

      {slug: "check-rep", chapter: "SYSTEM CHECK",
       narrative: "As you interact with factions, you'll build reputation.\n" \
                  "Reputation unlocks access to restricted zones, vendors, and missions.",
       hint: "Type <span style='color: #22d3ee;'>rep</span> to view your reputation standing.",
       condition: {type: :command_used, match: %w[rep reputation standing]}},

      {slug: "graduation", chapter: "SYSTEM CHECK",
       narrative: "All systems green. Training complete.\n" \
                  "Proceed to the Graduation Chamber to choose your starting location.",
       hint: "Navigate to the Graduation Chamber — south from the Systems Lab.",
       condition: {type: :in_room, target: "bl-graduation-chamber"}},

      {slug: "choose-start", chapter: "DEPLOYMENT",
       narrative: nil, # Rendered by render_starting_room_selection
       hint: "Type <span style='color: #22d3ee;'>choose &lt;number&gt;</span> to select your starting location.",
       condition: {type: :choosing_start}}
    ].freeze

    CHAPTER_COLORS = {
      "BOOT SEQUENCE" => "#22d3ee",
      "INTERFACE TRAINING" => "#60a5fa",
      "DECK OPERATIONS" => "#fbbf24",
      "BREACH TRAINING" => "#f87171",
      "SUPPLY CHAIN" => "#34d399",
      "TRANSIT OPERATIONS" => "#a78bfa",
      "SYSTEM CHECK" => "#f59e0b",
      "DEPLOYMENT" => "#34d399"
    }.freeze

    def initialize(hackr, input, parser)
      @hackr = hackr
      @input = input.to_s.strip
      @parser = parser
    end

    def execute
      return {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", event: nil} if input.empty?

      parts = input.split
      command = parts.first&.downcase
      args = parts[1..]

      step_index = hackr.stat("tutorial_step").to_i
      step = STEPS[step_index]

      # First command ever — show boot narrative + look
      if step_index == 0 && !hackr.stat("tutorial_boot_shown")
        hackr.set_stat!("tutorial_boot_shown", true)
        ensure_floor_items(step)
        narrative = render_narrative(step)
        look = parser.send(:dispatch_command, "look", [])
        look_output = look.is_a?(Hash) ? look[:output] : look
        return {output: narrative + "\n\n" + look_output + "\n" + render_hint(step), event: nil}
      end

      # Ensure current step's floor items exist before any command runs
      # (so `look` shows floor items placed on a prior step transition)
      ensure_floor_items(step) if step

      # Auto-advance if step condition was met externally (transit arrival, breach end).
      # Skip command-based conditions — they depend on the command about to run.
      @pre_advance_text = nil
      condition_type = step&.dig(:condition, :type)
      if step && !%i[command_used flag choosing_start].include?(condition_type) &&
          step_completed?(step, command, args, {})
        grant_step_items(step)
        step_index += 1
        hackr.set_stat!("tutorial_step", step_index)
        step = STEPS[step_index]
        if step
          ensure_floor_items(step)
          @pre_advance_text = render_step_completion(STEPS[step_index - 1], step)
        end
      end

      # Handle tutorial end (choose-start step or choosing flag set)
      if hackr.stat("tutorial_choosing_start") || step&.dig(:slug) == "choose-start"
        # Re-entry: warp back to origin, no starting room selection
        if hackr.stat("tutorial_return_room_id").present?
          tutorial_service.return_to_world!
          look = Grid::CommandParser.new(hackr, "look").execute[:output]
          return {output: render_deployment_complete(nil) + "\n\n" + look, event: nil}
        end
        hackr.set_stat!("tutorial_choosing_start", true)
        return handle_choose_start(command, args)
      end

      # Handle blocked commands
      if BLOCKED_COMMANDS.include?(command)
        return {output: blocked_message(command), event: nil}
      end

      # Gate economy commands to their relevant tutorial steps
      if step && command_gated?(command, step)
        return {output: "<span style='color: #9ca3af;'>That command isn't available yet. Follow the current training objective.</span>", event: nil}
      end

      # Handle code command (no step advancement)
      if command == "code"
        return {output: Grid::CodeService.new(hackr).execute(args&.join(" ")), event: nil}
      end

      # Handle help — tutorial-scoped (no step advancement)
      if command == "help" || command == "?"
        return {output: tutorial_help_command, event: nil}
      end

      # Handle choose — for starting room selection at graduation
      if command == "choose" && step&.dig(:slug) == "choose-start"
        hackr.set_stat!("tutorial_choosing_start", true)
        return handle_choose_start("choose", args)
      end

      # Tutorial-intercepted commands — set result and fall through to step completion
      result = if %w[rep reputation standing].include?(command)
        {output: fake_rep_command, event: nil}
      elsif %w[buy purchase].include?(command)
        {output: tutorial_buy_command(args&.join(" ")), event: nil}
      elsif command == "sell"
        {output: tutorial_sell_command(args&.join(" ")), event: nil}
      elsif command == "repair" && step && in_repair_step?
        {output: free_repair_command, event: nil}
      elsif command == "rig" && args&.first&.downcase&.in?(%w[install uninstall])
        handle_tutorial_rig(args)
      end

      # Delegate to main parser if not intercepted
      unless result
        result = parser.send(:dispatch_command, command, args)
        result = result.is_a?(Hash) ? result : {output: result, event: nil}
      end

      # Skip hint injection for passthrough commands
      return result if PASSTHROUGH_COMMANDS.include?(command)

      # Check step completion
      if step && step_completed?(step, command, args, result)
        # Grant items for the COMPLETING step (hackr just met the condition)
        grant_step_items(step)

        step_index += 1
        hackr.set_stat!("tutorial_step", step_index)

        next_step = STEPS[step_index]
        if next_step
          ensure_floor_items(next_step)

          if next_step[:slug] == "choose-start"
            completion_text = "\n<span style='color: #34d399;'>✓ Step complete</span>"

            if hackr.stat("tutorial_return_room_id").present?
              # Re-entry: warp back to origin, no selection needed
              tutorial_service.return_to_world!
              look = Grid::CommandParser.new(hackr, "look").execute[:output]
              completion_text += "\n" + render_deployment_complete(nil) + "\n\n" + look
            else
              # First-time: show starting room selection
              starting_rooms = GridStartingRoom.ordered.includes(:grid_room)
              if starting_rooms.any?
                hackr.set_stat!("tutorial_choosing_start", true)
                completion_text += "\n" + render_starting_room_selection(starting_rooms)
              else
                tutorial_service.complete!(starting_room: hackr.current_room)
                completion_text += "\n" + render_deployment_complete(nil, first_time: true)
              end
            end
            result[:output] = result[:output].to_s + completion_text
          else
            completion_text = render_step_completion(step, next_step)
            result[:output] = result[:output].to_s + "\n" + completion_text
          end
        end
      elsif step
        # Show hint if not completed
        result[:output] = result[:output].to_s + "\n" + render_hint(step)
      end

      # Prepend auto-advance text if step was pre-completed (transit arrival, breach end)
      if @pre_advance_text
        result[:output] = @pre_advance_text + "\n" + result[:output].to_s
      end

      result
    end

    private

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end

    # ─── Step Completion Checks ──────────────────────────────────────

    def step_completed?(step, command, _args, result)
      cond = step[:condition]
      case cond[:type]
      when :command_used
        cond[:match].include?(command)
      when :in_room
        hackr.current_room&.slug == cond[:target]
      when :has_item
        hackr.grid_items.joins(:grid_item_definition)
          .where(grid_item_definitions: {slug: cond[:target]})
          .where(grid_mining_rig_id: nil, container_id: nil, equipped_slot: nil)
          .exists?
      when :not_has_item
        !hackr.grid_items.joins(:grid_item_definition)
          .where(grid_item_definitions: {slug: cond[:target]})
          .exists?
      when :stat_positive
        hackr.stat(cond[:target]).to_i > 0
      when :dialogue_depth
        ctx = hackr.stat("dialogue_context")
        ctx.is_a?(Hash) && ctx.values.any? { |path| path.is_a?(Array) && path.length >= cond[:target].to_i }
      when :moved
        result.is_a?(Hash) && result.dig(:event, :type) == "movement"
      when :deck_not_fried
        deck = hackr.equipped_deck
        deck && !deck.deck_fried?
      when :deck_has_software
        hackr.equipped_deck&.loaded_software&.any? || false
      when :deck_software_count
        (hackr.equipped_deck&.loaded_software&.count || 0) >= cond[:target].to_i
      when :breach_completed
        GridHackrBreach.where(grid_hackr: hackr, state: "success")
          .joins(:grid_breach_template)
          .where(grid_breach_templates: {slug: cond[:target]})
          .exists?
      when :rig_inactive
        hackr.grid_mining_rig&.active? == false
      when :rig_not_functional
        hackr.grid_mining_rig&.functional? == false
      when :rig_functional
        hackr.grid_mining_rig&.functional? || false
      when :rig_active
        hackr.grid_mining_rig&.active? || false
      when :flag
        @tutorial_flags&.include?(cond[:target])
      when :choosing_start
        hackr.stat("tutorial_choosing_start") == true
      else
        false
      end
    end

    # ─── Item Grants ─────────────────────────────────────────────────

    def ensure_floor_items(step)
      return unless (floor_item = step[:ensure_floor_item])
      ensure_floor_item(floor_item[:slug], floor_item[:room])
    end

    def grant_step_items(step)
      return unless step[:grants]

      granted_steps = hackr.stat("tutorial_granted_steps") || []
      return if granted_steps.include?(step[:slug])

      hackr.set_stat!("tutorial_granted_steps", granted_steps + [step[:slug]])

      step[:grants].each do |grant|
        defn = GridItemDefinition.find_by(slug: grant[:slug])
        next unless defn

        qty = grant[:quantity] || 1

        ActiveRecord::Base.transaction do
          if grant[:equip]
            # Create and auto-equip (e.g., DECK)
            item = GridItem.create!(defn.item_attributes.merge(grid_hackr: hackr, equipped_slot: "deck"))
            if grant[:fried_level]
              item.update!(properties: item.properties.merge("fried_level" => grant[:fried_level]))
            end
          elsif grant[:deck_load]
            # Load software onto equipped deck
            deck = hackr.equipped_deck
            if deck
              GridItem.create!(defn.item_attributes.merge(grid_hackr: hackr, deck_id: deck.id))
            end
          else
            Grid::Inventory.grant_item!(hackr: hackr, definition: defn, quantity: qty)
          end
        rescue Grid::InventoryErrors::InventoryFull, Grid::InventoryErrors::StackLimitExceeded
          # Silently skip if inventory is full
        end
      end
    end

    def ensure_floor_item(slug, room_slug)
      room = GridRoom.find_by(slug: room_slug)
      defn = GridItemDefinition.find_by(slug: slug)
      return unless room && defn

      # Only create if none exist on the floor of this room
      unless room.grid_items.joins(:grid_item_definition)
          .where(grid_item_definitions: {slug: slug}).exists?
        GridItem.create!(defn.item_attributes.merge(room: room))
      end
    end

    # ─── Rendering ───────────────────────────────────────────────────

    def render_narrative(step)
      return "" unless step[:narrative]

      chapter_color = CHAPTER_COLORS[step[:chapter]] || "#22d3ee"
      progress = render_progress_bar

      lines = []
      lines << "<span style='color: #{chapter_color};'>━━━ #{step[:chapter]} ━━━</span> #{progress}"
      lines << "<span style='color: #d0d0d0;'>#{step[:narrative]}</span>"

      "\n<div style='border-left: 2px solid #{chapter_color}; padding: 6px 12px; margin: 4px 0; background: #0a1420;'>" \
        "#{lines.join("\n")}</div>"
    end

    def render_hint(step)
      return "" unless step
      chapter_color = CHAPTER_COLORS[step[:chapter]] || "#22d3ee"
      "\n<div style='border-left: 2px solid #{chapter_color}; padding: 4px 12px; margin: 2px 0; background: #0a1420;'>" \
        "<span style='color: #{chapter_color};'>▸</span> <span style='color: #9ca3af;'>#{step[:hint]}</span></div>"
    end

    def render_step_completion(completed_step, next_step)
      lines = []
      lines << ""
      lines << "<span style='color: #34d399;'>✓ Step complete</span>"
      # Show grant narrative from the step that just completed (hackr met the condition)
      if completed_step[:grant_narrative]
        lines << ""
        lines << completed_step[:grant_narrative]
      end
      # Show next step's narrative and hint
      lines << render_narrative(next_step) if next_step[:narrative]
      lines << render_hint(next_step)
      lines.join("\n")
    end

    def render_progress_bar
      step_index = hackr.stat("tutorial_step").to_i
      total = STEPS.size
      pct = ((step_index.to_f / total) * 100).round
      filled = (pct / 5.0).round
      empty = 20 - filled
      bar = "█" * filled + "░" * empty
      "<span style='color: #6b7280;'>[#{bar}] #{pct}%</span>"
    end

    # ─── Starting Room Selection ─────────────────────────────────────

    def handle_choose_start(command, args)
      starting_rooms = GridStartingRoom.ordered.includes(:grid_room)
      if starting_rooms.empty?
        tutorial_service.complete!(starting_room: hackr.current_room)
        hackr.set_stat!("tutorial_choosing_start", false)
        return {output: render_deployment_complete, event: nil}
      end

      if command == "choose" && args&.first
        index = args.first.to_i - 1
        if index >= 0 && index < starting_rooms.size
          sr = starting_rooms.to_a[index]
          hackr.set_stat!("tutorial_choosing_start", false)

          # Capture before complete! changes the state
          was_first_time = tutorial_service.first_time?

          if was_first_time
            tutorial_service.complete!(starting_room: sr.grid_room)
          else
            tutorial_service.return_to_world!
            hackr.update!(current_room: sr.grid_room)
          end

          look = Grid::CommandParser.new(hackr, "look").execute[:output]
          return {output: render_deployment_complete(sr.name, first_time: was_first_time) + "\n\n" + look, event: nil}
        else
          return {output: "<span style='color: #f87171;'>Invalid selection. Choose a number between 1 and #{starting_rooms.size}.</span>", event: nil}
        end
      end

      # Show the selection list
      output = render_starting_room_selection(starting_rooms)
      {output: output, event: nil}
    end

    def render_starting_room_selection(starting_rooms)
      lines = []
      lines << ""
      lines << "<span style='color: #34d399;'>━━━ DEPLOYMENT ━━━</span> #{render_progress_bar}"
      lines << "<span style='color: #22d3ee; font-weight: bold;'>TRAINING COMPLETE — CHOOSE YOUR DEPLOYMENT ZONE</span>"
      lines << ""
      lines << "<span style='color: #d0d0d0;'>Where you start shapes your early experience on the Grid.</span>"
      lines << "<span style='color: #d0d0d0;'>Each zone has its own factions, threats, and opportunities.</span>"
      lines << ""

      starting_rooms.each_with_index do |sr, i|
        lines << "<span style='color: #fbbf24;'>[#{i + 1}]</span> <span style='color: #22d3ee; font-weight: bold;'>#{h(sr.name)}</span>"
        lines << "    <span style='color: #d0d0d0;'>#{h(sr.blurb)}</span>"
        lines << ""
      end

      lines << "<span style='color: #9ca3af;'>Type</span> <span style='color: #22d3ee;'>choose &lt;number&gt;</span> <span style='color: #9ca3af;'>to deploy.</span>"
      lines.join("\n")
    end

    def render_deployment_complete(location_name = nil, first_time: false)
      lines = []
      lines << ""
      lines << "<span style='color: #34d399; font-weight: bold;'>════════════════════════════════════════════════════════════════</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>  BOOTLOADER COMPLETE — DEPLOYING TO THE PULSE GRID</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>════════════════════════════════════════════════════════════════</span>"
      lines << ""
      lines << "<span style='color: #d0d0d0;'>Welcome to THE PULSE GRID, #{h(hackr.hackr_alias)}.</span>"
      lines << "<span style='color: #d0d0d0;'>Your journey with the Fracture Network begins now.</span>" if first_time
      lines << "<span style='color: #9ca3af;'>Deploying to: #{h(location_name)}</span>" if location_name
      lines << ""
      lines << "<span style='color: #6b7280;'>Type <span style='color: #22d3ee;'>help</span> for commands. Type <span style='color: #22d3ee;'>look</span> to observe.</span>"
      lines.join("\n")
    end

    # ─── Special Command Handlers ────────────────────────────────────

    def blocked_message(command)
      case command
      when "say"
        "<span style='color: #9ca3af;'>Communications restricted during training simulation.</span>"
      else
        "<span style='color: #9ca3af;'>That action is disabled during training.</span>"
      end
    end

    def set_flag!(flag)
      @tutorial_flags ||= []
      @tutorial_flags << flag
    end

    def command_gated?(command, step)
      GATED_COMMANDS.each do |commands, allowed_steps|
        next unless commands.include?(command)
        return !allowed_steps.include?(step[:slug])
      end
      false
    end

    # Simulated buy — grants item directly, no shop stock or CRED involved
    TUTORIAL_SHOP_ITEMS = %w[training-data-chip training-stim-pack].freeze

    def tutorial_buy_command(item_name)
      return "<span style='color: #fbbf24;'>Buy what? Usage: buy &lt;item&gt;</span>" if item_name.to_s.strip.empty?

      slug = TUTORIAL_SHOP_ITEMS.find do |s|
        defn = GridItemDefinition.find_by(slug: s)
        defn && defn.name.downcase == item_name.strip.downcase
      end

      unless slug
        return "<span style='color: #f87171;'>VECTOR doesn't stock '#{h(item_name)}'.</span>"
      end

      defn = GridItemDefinition.find_by(slug: slug)
      ActiveRecord::Base.transaction do
        Grid::Inventory.grant_item!(hackr: hackr, definition: defn, quantity: 1)
      end

      set_flag!("tutorial_buy_succeeded")
      "<span style='color: #34d399;'>Purchased: #{h(defn.name)}.</span>\n" \
        "<span style='color: #9ca3af;'>In the real Grid, this would cost CRED.</span>"
    rescue Grid::InventoryErrors::InventoryFull
      "<span style='color: #f87171;'>Inventory full.</span>"
    end

    # Simulated sell — destroys item, no CRED granted
    def tutorial_sell_command(item_name)
      return "<span style='color: #fbbf24;'>Sell what? Usage: sell &lt;item&gt;</span>" if item_name.to_s.strip.empty?

      item = hackr.grid_items.in_inventory(hackr)
        .find_by("LOWER(name) = ?", item_name.strip.downcase)
      unless item
        return "<span style='color: #f87171;'>You don't have '#{h(item_name)}' to sell.</span>"
      end

      name = item.name
      if item.quantity > 1
        item.update!(quantity: item.quantity - 1)
      else
        item.destroy!
      end

      set_flag!("tutorial_sell_succeeded")
      "<span style='color: #34d399;'>Sold: #{h(name)}.</span>\n" \
        "<span style='color: #9ca3af;'>In the real Grid, you'd receive CRED for this.</span>"
    end

    def in_repair_step?
      step_index = hackr.stat("tutorial_step").to_i
      step = STEPS[step_index]
      step && step[:slug] == "repair-deck"
    end

    def free_repair_command
      deck = hackr.equipped_deck
      unless deck
        return "<span style='color: #f87171;'>No DECK equipped.</span>"
      end
      unless deck.deck_fried?
        return "<span style='color: #9ca3af;'>Your DECK doesn't need repair.</span>"
      end
      room = hackr.current_room
      unless room&.room_type == "repair_service"
        return "<span style='color: #f87171;'>There's no repair service here.</span>"
      end

      fried_level = deck.deck_fried_level
      deck.update!(properties: deck.properties.merge("fried_level" => 0))

      lines = []
      lines << ""
      lines << "<span style='color: #34d399; font-weight: bold;'>[ DECK REPAIR COMPLETE ]</span>"
      lines << "<span style='color: #d0d0d0;'>  DECK: #{h(deck.name)}</span>"
      lines << "<span style='color: #9ca3af;'>  Damage cleared: level #{fried_level}/5</span>"
      lines << "<span style='color: #fbbf24;'>  Cost: 0 CRED (training sim)</span>"
      lines.join("\n")
    end

    def handle_tutorial_rig(args)
      subcommand = args.first&.downcase
      item_name = args[1..]&.join(" ")

      rig = hackr.grid_mining_rig
      unless rig
        return {output: "<span style='color: #f87171;'>You don't have a mining rig.</span>", event: nil}
      end

      if subcommand == "install"
        return {output: tutorial_rig_install(rig, item_name), event: nil}
      elsif subcommand == "uninstall"
        return {output: tutorial_rig_uninstall(rig, item_name), event: nil}
      end

      # Shouldn't reach here, but delegate just in case
      result = parser.send(:dispatch_command, "rig", args)
      result.is_a?(Hash) ? result : {output: result, event: nil}
    end

    def tutorial_rig_install(rig, item_name)
      return "<span style='color: #fbbf24;'>Install what? Usage: rig install &lt;component&gt;</span>" if item_name.to_s.empty?

      if rig.active?
        return "<span style='color: #f87171;'>Rig must be offline to install components. Type 'rig off' first.</span>"
      end

      item = hackr.grid_items.in_inventory(hackr)
        .where(item_type: "rig_component")
        .find_by("LOWER(name) = ?", item_name.downcase)
      unless item
        return "<span style='color: #f87171;'>No rig component '#{h(item_name)}' in inventory.</span>"
      end

      slot = item.properties&.dig("slot")
      unless slot
        return "<span style='color: #f87171;'>#{h(item.name)} has no component slot defined.</span>"
      end

      # Check slot capacity
      unless rig.slot_available?(slot)
        return "<span style='color: #f87171;'>No #{slot} slot available on your rig.</span>"
      end

      item.update!(grid_mining_rig: rig, grid_hackr: nil)

      output = "<span style='color: #34d399;'>Installed #{h(item.name)} into rig.</span>"
      output += "\n<span style='color: #34d399; font-weight: bold;'>Rig is now FUNCTIONAL.</span>" if rig.reload.functional?
      output += "\n<span style='color: #f87171;'>Rig still non-functional — missing components.</span>" unless rig.functional?
      output
    end

    def tutorial_rig_uninstall(rig, item_name)
      return "<span style='color: #fbbf24;'>Uninstall what? Usage: rig uninstall &lt;component&gt;</span>" if item_name.to_s.empty?

      if rig.active?
        return "<span style='color: #f87171;'>Rig must be offline to remove components. Type 'rig off' first.</span>"
      end

      item = rig.components.find_by("LOWER(name) = ?", item_name.downcase)
      unless item
        return "<span style='color: #f87171;'>No component '#{h(item_name)}' installed in your rig.</span>"
      end

      item.update!(grid_mining_rig: nil, grid_hackr: hackr)
      "<span style='color: #fbbf24;'>Removed #{h(item.name)} from rig → inventory.</span>"
    end

    def fake_rep_command
      lines = []
      lines << "\n<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines << "<span style='color: #22d3ee; font-weight: bold;'>STANDING REPORT :: #{h(hackr.hackr_alias)}</span>"
      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines << ""
      lines << "<span style='color: #9ca3af;'>This is a preview of what your reputation report will look like</span>"
      lines << "<span style='color: #9ca3af;'>as you interact with factions across THE PULSE GRID:</span>"
      lines << ""
      lines << "<span style='color: #22d3ee;'>Fracture Network      </span> <span style='color: #34d399;'>████████████████████ Trusted    (+1250)</span>"
      lines << "<span style='color: #fbbf24;'>  ↳ Signal Corps       </span> <span style='color: #34d399;'>██████████████████░░ Respected  (+980)</span>"
      lines << "<span style='color: #fbbf24;'>  ↳ Deep Circuit       </span> <span style='color: #60a5fa;'>███████████████░░░░░ Friendly   (+720)</span>"
      lines << "<span style='color: #f87171;'>GovCorp               </span> <span style='color: #f87171;'>████░░░░░░░░░░░░░░░░ Hostile    (-850)</span>"
      lines << "<span style='color: #fbbf24;'>  ↳ RAINN Division     </span> <span style='color: #f87171;'>██░░░░░░░░░░░░░░░░░░ Despised   (-1200)</span>"
      lines << "<span style='color: #a78bfa;'>Underbelly Collective  </span> <span style='color: #fbbf24;'>██████████░░░░░░░░░░ Neutral    (+200)</span>"
      lines << ""
      lines << "<span style='color: #6b7280;'>Reputation grows through missions, NPC interactions, and faction-aligned actions.</span>"
      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines.join("\n")
    end

    def tutorial_help_command
      step_index = hackr.stat("tutorial_step").to_i
      step = STEPS[step_index]

      lines = []
      lines << "<span style='color: #22d3ee; font-weight: bold;'>BOOTLOADER — Training Commands</span>"
      lines << ""
      lines << "<span style='color: #fbbf24;'>Navigation:</span>"
      lines << "  <span style='color: #22d3ee;'>look</span> / <span style='color: #22d3ee;'>l</span>          — Observe your surroundings"
      lines << "  <span style='color: #22d3ee;'>north</span> <span style='color: #22d3ee;'>south</span> etc.  — Move in a direction"
      lines << "  <span style='color: #22d3ee;'>go &lt;direction&gt;</span>    — Move in a direction"
      lines << ""
      lines << "<span style='color: #fbbf24;'>Interaction:</span>"
      lines << "  <span style='color: #22d3ee;'>talk &lt;npc&gt;</span>        — Talk to an NPC"
      lines << "  <span style='color: #22d3ee;'>ask &lt;npc&gt; about &lt;topic&gt;</span> — Ask about a topic"
      lines << "  <span style='color: #22d3ee;'>examine &lt;target&gt;</span>  — Examine something in detail"
      lines << ""
      lines << "<span style='color: #fbbf24;'>Items:</span>"
      lines << "  <span style='color: #22d3ee;'>inventory</span> / <span style='color: #22d3ee;'>inv</span>   — Check your inventory"
      lines << "  <span style='color: #22d3ee;'>take &lt;item&gt;</span>       — Pick up an item"
      lines << "  <span style='color: #22d3ee;'>use &lt;item&gt;</span>        — Use a consumable item"
      lines << "  <span style='color: #22d3ee;'>drop &lt;item&gt;</span>       — Drop an item"
      lines << ""
      lines << "<span style='color: #fbbf24;'>DECK:</span>"
      lines << "  <span style='color: #22d3ee;'>deck</span>              — DECK status"
      lines << "  <span style='color: #22d3ee;'>deck load &lt;sw&gt;</span>    — Load software"
      lines << "  <span style='color: #22d3ee;'>deck unload &lt;sw&gt;</span>  — Unload software"
      lines << "  <span style='color: #22d3ee;'>repair</span>            — Repair DECK at service point"
      lines << ""
      lines << "<span style='color: #fbbf24;'>Combat:</span>"
      lines << "  <span style='color: #22d3ee;'>breach</span>            — Initiate a BREACH encounter"
      lines << ""
      lines << "<span style='color: #fbbf24;'>Economy:</span>"
      lines << "  <span style='color: #22d3ee;'>shop</span>              — Browse vendor inventory"
      lines << "  <span style='color: #22d3ee;'>buy &lt;item&gt;</span>        — Purchase an item"
      lines << "  <span style='color: #22d3ee;'>sell &lt;item&gt;</span>       — Sell an item"
      lines << "  <span style='color: #22d3ee;'>salvage &lt;item&gt;</span>    — Break down an item"
      lines << "  <span style='color: #22d3ee;'>fabricate &lt;slug&gt;</span>  — Craft from schematic"
      lines << "  <span style='color: #22d3ee;'>schematics</span>        — List crafting recipes"
      lines << ""
      lines << "<span style='color: #fbbf24;'>Transit:</span>"
      lines << "  <span style='color: #22d3ee;'>transit</span>           — Transit info"
      lines << "  <span style='color: #22d3ee;'>board &lt;route&gt;</span>     — Board public transit"
      lines << "  <span style='color: #22d3ee;'>hail &lt;type&gt; to &lt;dest&gt;</span> — Hail private transit"
      lines << ""
      lines << "<span style='color: #fbbf24;'>Systems:</span>"
      lines << "  <span style='color: #22d3ee;'>stat</span>              — Your stats and vitals"
      lines << "  <span style='color: #22d3ee;'>rep</span>               — Reputation standing"
      lines << "  <span style='color: #22d3ee;'>rig</span>               — Mining rig status"
      lines << "  <span style='color: #22d3ee;'>who</span>               — Who's online"
      lines << ""

      if step
        lines << "<span style='color: #6b7280;'>Current objective:</span>"
        lines << "  #{render_hint(step).strip}"
      end

      lines.join("\n")
    end

    def tutorial_service
      @tutorial_service ||= TutorialService.new(hackr)
    end
  end
end
