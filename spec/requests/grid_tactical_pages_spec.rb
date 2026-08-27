require "rails_helper"

# Tactical surface (Hotwire migration Phase 6b–6d). Command mechanics are
# covered by the grid_game_pages + CommandRunner specs; this covers the
# shell, tab frames, and the tactical command-response fragments.
RSpec.describe "Grid tactical pages", type: :request do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone, name: "Relay Nexus") }
  let!(:hackr) do
    create(:grid_hackr, password: "hackthegrid", current_room: room,
      stats: {"tutorial_completed" => true})
  end

  def grant_tactical!(to = hackr)
    create(:feature_grant, grid_hackr: to, feature: FeatureGrant::TACTICAL_GRID)
    create(:feature_grant, grid_hackr: to, feature: FeatureGrant::PULSE_GRID)
  end

  def log_in!(as = hackr)
    post "/grid/login", params: {hackr_alias: as.hackr_alias, password: "hackthegrid"}
  end

  def turbo_stream_headers
    {"Accept" => "text/vnd.turbo-stream.html"}
  end

  describe "GET /grid/1337" do
    it "requires login" do
      get "/grid/1337"

      expect(response).to have_http_status(:redirect)
    end

    it "renders the coming-soon gate without the tactical_grid grant" do
      log_in!

      get "/grid/1337"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("will open soon")
    end

    it "renders the shell: bar, tabs, terminal with initial look, room stream, map region" do
      grant_tactical!
      log_in!

      get "/grid/1337"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("TACTICAL")
      expect(response.body).to include("KILLSWITCH")
      expect(response.body).to include('id="tactical-bar-status"')
      expect(response.body).to include("RELAY NEXUS") # inline initial look
      expect(response.body).to include(%(data-grid-room-id="#{room.id}"))
      expect(response.body).to include('id="tactical-refresh-bus"')
      expect(response.body).to include(%(src="/grid/1337/tabs/deck"))
      expect(response.body).to include('name="surface"')
      expect(response.body).to include('id="tactical-map"')
      expect(response.body).to include("turbo-cable-stream-source")
    end
  end

  describe "GET /grid/1337/tabs/:tab" do
    before do
      grant_tactical!
      log_in!
    end

    it "404s on unknown tabs" do
      get "/grid/1337/tabs/nope"

      expect(response).to have_http_status(:not_found)
    end

    it "renders the deck tab frame (no deck equipped)" do
      get "/grid/1337/tabs/deck"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="tactical-tab-deck"')
      expect(response.body).to include("No DECK equipped")
    end

    it "renders the loadout tab with empty slots" do
      get "/grid/1337/tabs/loadout"

      expect(response.body).to include("LOADOUT")
      expect(response.body).to include("—")
    end

    it "renders the rep tab" do
      get "/grid/1337/tabs/rep"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="tactical-tab-rep"')
    end

    it "renders the missions tab empty state" do
      get "/grid/1337/tabs/missions"

      expect(response.body).to include("No active missions")
    end

    it "renders the stats tab with clearance, vitals, and cred summary" do
      get "/grid/1337/tabs/stats"

      expect(response.body).to include("CL#{hackr.stat("clearance")}")
      expect(response.body).to include("VITALS")
      expect(response.body).to include("HEALTH")
      expect(response.body).to include("ACHIEVEMENTS")
    end

    it "renders the inventory tab with capacity and item dialogs" do
      create(:grid_item, :in_inventory, grid_hackr: hackr, name: "Scrap Coil", item_type: "material", quantity: 3)

      get "/grid/1337/tabs/inventory"

      expect(response.body).to include("Inventory")
      expect(response.body).to include("Scrap Coil")
      expect(response.body).to include("x3")
      expect(response.body).to include(%(value="drop Scrap Coil"))
      expect(response.body).to include("tactical-dialog")
    end

    it "renders the cred tab with the new-cache command form" do
      get "/grid/1337/tabs/cred"

      expect(response.body).to include("Total CRED")
      expect(response.body).to include(%(value="cache create"))
    end

    it "renders the schematics tab" do
      get "/grid/1337/tabs/schematics"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="tactical-tab-schematics"')
    end
  end

  describe "GET /grid/1337/panels/:panel" do
    before do
      grant_tactical!
      log_in!
    end

    it "404s on unknown panels" do
      get "/grid/1337/panels/nope"

      expect(response).to have_http_status(:not_found)
    end

    it "renders the vendor panel with listings and sell list" do
      vendor = create(:grid_mob, grid_room: room, mob_type: "vendor", name: "Fixer Yin")
      create(:grid_shop_listing, grid_mob: vendor)

      get "/grid/1337/panels/vendor"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("VENDOR :: Fixer Yin")
      expect(response.body).to include("BUY")
      expect(response.body).to include("SELL")
    end

    it "renders the vendor empty state without a vendor" do
      get "/grid/1337/panels/vendor"

      expect(response.body).to include("No vendor here.")
    end

    it "renders the transit panel browser" do
      get "/grid/1337/panels/transit"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("TRANSIT")
      expect(response.body).to include("SLIPSTREAM")
      expect(response.body).to include("Corridor Heat")
    end

    it "renders the npc panel with dialogue topics as command forms" do
      mob = create(:grid_mob, grid_room: room, name: "Archivist",
        dialogue_tree: {"greeting" => "State your query.", "topics" => {"lore" => "Old stories."}})

      get "/grid/1337/panels/npc", params: {mob_id: mob.id}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("NPC :: Archivist")
      expect(response.body).to include("State your query.")
      expect(response.body).to include(%(value="ask Archivist about lore"))
    end

    it "renders a quest giver's available mission with the ACCEPT form (all_met? regression)" do
      giver = create(:grid_mob, :quest_giver, grid_room: room, name: "Broker Nyx",
        dialogue_tree: {"greeting" => "Need work?"})
      mission = create(:grid_mission, giver_mob: giver, name: "Cable Run")

      get "/grid/1337/panels/npc", params: {mob_id: giver.id}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MISSIONS")
      expect(response.body).to include("Cable Run")
      expect(response.body).to include(%(value="accept #{mission.slug}"))
    end

    it "mirrors leaf dialogue responses into the npc panel (panel-render regression)" do
      # Leaf topics (and mission/unknown/ancestor answers) never move the
      # persisted dialogue context — the panel shows the recorded last
      # exchange instead of reconstructing from state.
      mob = create(:grid_mob, grid_room: room, name: "Archivist",
        dialogue_tree: {"greeting" => "State your query.", "topics" => {"lore" => "The old grid never died."}})

      post "/grid/commands", params: {input: "ask Archivist about lore", surface: "tactical"}, headers: turbo_stream_headers
      get "/grid/1337/panels/npc", params: {mob_id: mob.id}

      expect(response.body).to include("The old grid never died.")
      expect(response.body).to include("tactical-npc-exchange")
      # Topics stay BUTTONS after the mirror — the terminal's plain-text
      # topic list must not ride into the panel and shadow them.
      expect(response.body).to include(%(value="ask Archivist about lore"))
      expect(response.body).not_to include("You can ask about:")
    end

    it "does not leak another NPC's exchange into a different panel" do
      create(:grid_mob, grid_room: room, name: "Archivist",
        dialogue_tree: {"greeting" => "State your query.", "topics" => {"lore" => "The old grid never died."}})
      other_mob = create(:grid_mob, grid_room: room, name: "Broker",
        dialogue_tree: {"greeting" => "Buying or selling?"})

      post "/grid/commands", params: {input: "ask Archivist about lore", surface: "tactical"}, headers: turbo_stream_headers
      get "/grid/1337/panels/npc", params: {mob_id: other_mob.id}

      expect(response.body).not_to include("The old grid never died.")
      expect(response.body).to include("Buying or selling?")
    end

    it "renders the rest pod panel in a rest_pod room" do
      hackr.update!(current_room: create(:grid_room, grid_zone: zone, room_type: "rest_pod"))

      get "/grid/1337/panels/rest_pod"

      expect(response.body).to include("REST POD")
      expect(response.body).to include("pts/CRED")
    end
  end

  describe "room flags + map on movement" do
    it "replaces the room-flags region and the zone map when a tactical command moves the hackr" do
      target = create(:grid_room, grid_zone: zone, name: "Vendor Row")
      create(:grid_exit, from_room: room, to_room: target, direction: "north", requires_item_id: nil)
      create(:grid_mob, grid_room: target, mob_type: "vendor", name: "Stall Keeper")
      grant_tactical!
      log_in!

      post "/grid/commands", params: {input: "go north", surface: "tactical"}, headers: turbo_stream_headers

      expect(response.body).to include('action="replace" target="tactical-room-flags"')
      expect(response.body).to include('data-panel="vendor"')
      expect(response.body).to include('action="replace" target="tactical-map"')
      expect(response.body).to include(%(data-room-id="#{target.id}"))
    end

    it "does not rebuild the map for non-movement commands" do
      grant_tactical!
      log_in!

      post "/grid/commands", params: {input: "look", surface: "tactical"}, headers: turbo_stream_headers

      expect(response.body).not_to include('target="tactical-map"')
    end
  end

  describe "GET /grid/1337/map" do
    it "renders the SVG map with the current room highlighted and walkable directions" do
      target = create(:grid_room, grid_zone: zone, name: "Fiber Alley")
      create(:grid_exit, from_room: room, to_room: target, direction: "north", requires_item_id: nil)
      grant_tactical!
      log_in!

      get "/grid/1337/map"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="tactical-map"')
      expect(response.body).to include(%(data-room-id="#{room.id}"))
      expect(response.body).to include('data-direction="north"')
      expect(response.body).to include('data-controller="zone-presence"')
    end

    it "makes cross-zone ghost rooms clickable only when adjacent to the current room" do
      other_zone = create(:grid_zone)
      ghost_target = create(:grid_room, grid_zone: other_zone, name: "Distant Relay")
      create(:grid_exit, from_room: room, to_room: ghost_target, direction: "east", requires_item_id: nil)

      far_room = create(:grid_room, grid_zone: zone, name: "Far Corner")
      create(:grid_exit, from_room: room, to_room: far_room, direction: "north", requires_item_id: nil)
      far_ghost = create(:grid_room, grid_zone: other_zone, name: "Unreachable Relay")
      create(:grid_exit, from_room: far_room, to_room: far_ghost, direction: "east", requires_item_id: nil)

      grant_tactical!
      log_in!
      get "/grid/1337/map"

      # Adjacent ghost: navigable group carrying the exit direction.
      expect(response.body).to include("Distant Relay")
      expect(response.body).to match(/tactical-map-ghost tactical-map-room--walkable[^>]*data-direction="east"/)
      # Exactly ONE walkable ghost — a ghost off a non-current room never is.
      expect(response.body.scan("tactical-map-ghost tactical-map-room--walkable").size).to eq(1)
    end
  end

  describe "BREACH region (6d)" do
    it "renders the hidden breach shell when not in breach" do
      grant_tactical!
      log_in!

      get "/grid/1337"

      expect(response.body).to include('id="tactical-breach-shell" class="tactical-breach" hidden')
    end

    it "renders the live breach overlay with meta, protocols, and jackout" do
      breach = create(:grid_hackr_breach, grid_hackr: hackr, detection_level: 30, round_number: 2)
      grant_tactical!
      log_in!

      get "/grid/1337"

      expect(response.body).to include("BREACH ::")
      expect(response.body).to include(breach.grid_breach_template.name)
      expect(response.body).to include("ROUND 2")
      expect(response.body).to include("JACKOUT")
      expect(response.body).to include('id="breach-log"')
      expect(response.body).to include(%(value="status"))
    end

    it "routes in-breach tactical command output to the breach log and refreshes the meta" do
      create(:grid_hackr_breach, grid_hackr: hackr)
      grant_tactical!
      log_in!

      post "/grid/commands", params: {input: "status", surface: "tactical"}, headers: turbo_stream_headers

      expect(response.body).to include('action="replace" target="tactical-breach-meta"')
      expect(response.body).to include('action="append" target="breach-log"')
      expect(response.body).not_to include('action="append" target="grid-log"')
    end

    it "keeps legacy in-breach output on the main log" do
      create(:grid_hackr_breach, grid_hackr: hackr)
      grant_tactical!
      log_in!

      post "/grid/commands", params: {input: "status"}, headers: turbo_stream_headers

      expect(response.body).to include('action="append" target="grid-log"')
      expect(response.body).not_to include("breach-log")
    end

    it "numbers target dropdowns 1-based so every protocol is reachable (0-index regression)" do
      # Real generated breach: DB positions are 0-based, the parser
      # converts 1-based input with `num - 1`, terminal output prints
      # `position + 1`. Raw positions in the dropdowns shifted every
      # target and made the last protocol untargetable.
      template = create(:grid_breach_template)
      encounter = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room)
      deck_def = create(:grid_item_definition, :gear, slug: "regression-deck", name: "Regression Deck",
        properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
      deck = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
      deck.update!(equipped_slot: "deck")
      breach = Grid::BreachService.start!(hackr: hackr, encounter: encounter).hackr_breach
      protocol_count = breach.grid_breach_protocols.count
      expect(protocol_count).to be >= 1
      expect(breach.grid_breach_protocols.minimum(:position)).to eq(0) # DB really is 0-based

      grant_tactical!
      log_in!
      get "/grid/1337"

      # Target menus submit complete 1-based commands (TargetSelector port).
      expect(response.body).to include('class="target-menu"')
      expect(response.body).to include(%(value="analyze 1"))
      expect(response.body).to include(%(value="analyze #{protocol_count}"))
      expect(response.body).not_to include(%(value="analyze 0"))
      expect(response.body).to include(%(value="reroute #{protocol_count}"))
    end
  end

  describe "POST /grid/commands with surface=tactical" do
    it "adds the tactical fragments to the response" do
      grant_tactical!
      log_in!

      post "/grid/commands", params: {input: "look", surface: "tactical"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="append" target="grid-log"')
      expect(response.body).to include('action="replace" target="tactical-bar-status"')
      expect(response.body).to include('action="append" target="tactical-refresh-bus"')
      expect(response.body).to include("frame-refresher")
    end

    it "keeps the legacy response free of tactical fragments" do
      grant_tactical!
      log_in!

      post "/grid/commands", params: {input: "look"}, headers: turbo_stream_headers

      expect(response.body).not_to include("tactical-bar-status")
      expect(response.body).not_to include("frame-refresher")
    end
  end
end
