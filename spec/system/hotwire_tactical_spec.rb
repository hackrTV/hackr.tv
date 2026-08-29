require "rails_helper"

# Phase 6b–6d: the tactical surface on Hotwire. Commands ride the shared
# bus; tabs/panels are lazy frames; the map is server-rendered SVG with
# click-to-move; BREACH is a server-rendered overlay on the same bus.
RSpec.describe "Hotwire tactical", type: :system do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone, name: "Relay Nexus") }
  let!(:hackr) do
    h = create(:grid_hackr, hackr_alias: "TacRunner", password: "hackthegrid",
      current_room: room, stats: {"tutorial_completed" => true})
    create(:feature_grant, grid_hackr: h, feature: FeatureGrant::TACTICAL_GRID)
    create(:feature_grant, grid_hackr: h, feature: FeatureGrant::PULSE_GRID)
    h
  end

  def log_in!
    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  def open_tactical!
    visit "/grid/1337"
    expect(page).to have_content("TACTICAL")
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
  end

  it "renders the shell, lazy-loads the default tab, and executes commands without reload" do
    log_in!
    open_tactical!

    expect(page).to have_content("RELAY NEXUS") # initial look
    expect(page).to have_content("No DECK equipped", wait: 10) # deck tab frame loaded

    page.execute_script("window.__turbo_marker = true")
    fill_in "input", with: "who"
    find(".tactical-command-form .grid-command-input").send_keys(:enter)

    expect(page).to have_content("> who", wait: 10)
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true)
  end

  it "switches status tabs and lazy-loads their frames" do
    log_in!
    open_tactical!

    click_button "STATS"
    expect(page).to have_content("VITALS", wait: 10)
    expect(page).to have_content("ACHIEVEMENTS")

    click_button "INV"
    expect(page).to have_content("Inventory", wait: 10)
  end

  it "moves via map click and re-renders the map + flags" do
    target = create(:grid_room, grid_zone: zone, name: "Fiber Alley")
    create(:grid_exit, from_room: room, to_room: target, direction: "north", requires_item_id: nil)
    create(:grid_exit, from_room: target, to_room: room, direction: "south", requires_item_id: nil)
    create(:grid_mob, grid_room: target, mob_type: "vendor", name: "Stall Keeper")

    log_in!
    open_tactical!
    expect(page).to have_css("[data-direction='north']", visible: :all, wait: 10)

    find("[data-direction='north'] polygon:nth-of-type(3)", visible: :all).click

    expect(page).to have_content("FIBER ALLEY", wait: 10) # go output in terminal
    expect(page).to have_css("button[data-panel='vendor']", wait: 10) # flags re-rendered
    expect(page).to have_css("[data-direction='south']", visible: :all, wait: 10) # map re-rendered from new room
  end

  it "opens the vendor panel as a lazy frame" do
    create(:grid_mob, grid_room: room, mob_type: "vendor", name: "Fixer Yin")

    log_in!
    open_tactical!

    find("button[data-panel='vendor']").click

    expect(page).to have_content("VENDOR :: Fixer Yin", wait: 10)
    expect(page).to have_content("Nothing for sale.")

    click_button "CLOSE"
    expect(page).to have_css("button[data-panel='vendor']", wait: 10) # handles back
  end

  it "runs a breach through the overlay: status output, then jackout closes it" do
    create(:grid_hackr_breach, grid_hackr: hackr)

    log_in!
    open_tactical!

    expect(page).to have_content("BREACH ::")
    expect(page).to have_content("ROUND 1")

    within("#tactical-breach-shell") do
      click_button "STATUS"
    end
    expect(page).to have_css("#breach-log .grid-line", wait: 10) # output routed to breach log

    within("#tactical-breach-shell") do
      click_button "JACKOUT" # opens the dialog
    end
    within("dialog[open]") do
      click_button "JACKOUT"
    end

    expect(page).to have_css("#tactical-breach-shell[hidden]", visible: :all, wait: 10)
    expect(hackr.reload.active_breach).to be_nil
  end

  it "shows NPC responses inside the dialogue slide-in" do
    create(:grid_mob, grid_room: room, name: "Archivist",
      dialogue_tree: {"greeting" => "State your query.", "topics" => {"lore" => "The old grid never died."}})

    log_in!
    open_tactical!

    # NPC handle fires `talk to` AND opens the panel. Assertions are
    # scoped to the panel region — the terminal log echoes the same
    # text, so page-wide matches would pass before the frame loads
    # (full-suite flake) and wouldn't prove the SLIDE-IN renders it.
    find("button[data-panel='npc']").click
    within("#tactical-room-flags") do
      expect(page).to have_content("State your query.", wait: 10) # frame loaded
      click_button "lore"
    end

    # Leaf topic round-trips the bus; the refresh bus reloads the open
    # panel; the response renders in the slide-in. Two-stage wait: the
    # terminal log proves the command round-trip finished, THEN the
    # panel frame gets its own window for the refresh-bus reload —
    # single-stage wait: 10 flaked consistently on CI runners.
    expect(page).to have_content("The old grid never died.", wait: 30)
    within("#tactical-room-flags") do
      expect(page).to have_content("The old grid never died.", wait: 30)
    end
  end

  it "navigates into the next zone by clicking a phantom room" do
    other_zone = create(:grid_zone)
    ghost_room = create(:grid_room, grid_zone: other_zone, name: "Distant Relay")
    create(:grid_exit, from_room: room, to_room: ghost_room, direction: "east", requires_item_id: nil)
    create(:grid_exit, from_room: ghost_room, to_room: room, direction: "west", requires_item_id: nil)

    log_in!
    open_tactical!
    expect(page).to have_css(".tactical-map-ghost.tactical-map-room--walkable[data-direction='east']", visible: :all, wait: 10)

    find(".tactical-map-ghost.tactical-map-room--walkable polygon", visible: :all).click

    expect(page).to have_content("DISTANT RELAY", wait: 10) # go output — crossed zones
    expect(page).to have_css(%([data-grid-room-id="#{ghost_room.id}"]), visible: :all, wait: 10)
    # New zone's map rendered: the old room is now the ghost.
    expect(page).to have_css(".tactical-map-ghost[data-direction='west']", visible: :all, wait: 10)
  end

  it "targets the LAST protocol through the analyze dropdown (0-index regression)" do
    template = create(:grid_breach_template)
    encounter = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room)
    deck_def = create(:grid_item_definition, :gear, slug: "sys-regression-deck", name: "Sys Deck",
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
    deck = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    deck.update!(equipped_slot: "deck")
    breach = Grid::BreachService.start!(hackr: hackr, encounter: encounter).hackr_breach
    last_number = breach.grid_breach_protocols.count # 1-based display number of the 0-based max position

    log_in!
    open_tactical!
    expect(page).to have_content("BREACH ::")

    # TargetSelector UX: click ANALYZE, then pick the target in the menu.
    within("#tactical-breach-meta") do
      find("button.tactical-quick-button", text: "ANALYZE").click
      find(".target-menu-option", text: /\A\[#{last_number}\]/).click
    end

    # Parser echoes the same 1-based number back — proof the highest
    # protocol is reachable and un-shifted.
    expect(page).to have_css("#breach-log .grid-line", text: "ANALYZE → Protocol [#{last_number}]", wait: 10)
  end

  it "keeps the permanent player alive navigating vault → tactical (Turbo nav)" do
    artist = create(:artist, name: "Wave Artist")
    release = create(:release, artist: artist)
    create(:track, :with_audio, artist: artist, release: release, title: "Tac Tone")

    log_in!
    visit "/vault"
    find(".track-row", text: "Tac Tone").click
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn", wait: 10)
    page.execute_script("window.__player_marker = true")

    page.execute_script("window.Turbo.visit('/grid/1337')")

    expect(page).to have_current_path("/grid/1337")
    expect(page).to have_content("TACTICAL")
    expect(page.evaluate_script("document.querySelector('#player-bar audio').paused")).to eq(false)
    expect(page.evaluate_script("window.__player_marker")).to eq(true)
  end
end
