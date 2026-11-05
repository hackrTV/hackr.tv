require "rails_helper"

# /root/grid_hackrs — the hackrs ledger, the inspector and its dev tools
# (stats, warp, rig) as console screens (console-ui-for-all-admin Phase
# 5, 2026-11-01).
RSpec.describe "Admin grid hackrs", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let(:region) { create(:grid_region, name: "Neon Flats") }
  let(:zone) { create(:grid_zone, grid_region: region, name: "Arcade Row") }
  let(:room) { create(:grid_room, grid_zone: zone, name: "Pixel Den") }
  let!(:runner) { create(:grid_hackr, hackr_alias: "Runner", current_room: room, last_activity_at: Time.current) }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def dev_tools!(on)
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return(on ? "true" : nil)
  end

  # .env sets ADMIN_DEV_TOOLS=true for local work; the gate is off here
  # unless an example turns it on.
  before do
    allow(ENV).to receive(:[]).and_call_original
    dev_tools!(false)
  end

  describe "the ledger" do
    it "denies non-admins" do
      log_in!(operative)
      get "/root/grid_hackrs"

      expect(response).not_to have_http_status(:ok)
    end

    it "numbers every hackr with the FILTER haystack, destinations and the prompt; dev links only with dev tools" do
      log_in!(admin)
      get "/root/grid_hackrs"

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("3 hackrs", "1 online", "1 admin", 'id="ledger-filter"', 'data-search="runner operative pixel den"')
      expect(body).to include("data-command=\"03\" href=\"/root/grid_hackrs/#{runner.id}\"", "/root/grid_hackrs/#{runner.id}/items", "[ITEMS]")
      expect(body).to include("[&gt;] GRID", "[ROOT]", "type a hackr number")
      expect(body).not_to include("[HACKRS]", "[STATS]", "[SANDBOX]", "DEV TOOLS ON")

      dev_tools!(true)
      get "/root/grid_hackrs"
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("DEV TOOLS ON", "[STATS]", "[WARP]", "rc-ledger--inspect-dev",
        "/root/grid_breach_sandbox/new?hackr_id=#{runner.id}", "/root/grid_npc_dialogue_tester/new?hackr_id=#{runner.id}", "/root/grid_pac_escape_tester/new?hackr_id=#{runner.id}")
    end

    it "counts ON from GridHackr.online and survives a hackr row with no role" do
      create(:grid_hackr, hackr_alias: "Drifter", last_activity_at: Time.current) # active, but in no room
      operative.update_column(:role, nil)
      log_in!(admin)

      get "/root/grid_hackrs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("4 hackrs", "1 online")
      get "/root/grid_hackrs/#{operative.id}"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "the inspector" do
    it "reads the hackr's record, numbers the active missions and gates the dev tools" do
      mission = create(:grid_mission, name: "Signal Run")
      assignment = create(:grid_hackr_mission, grid_hackr: runner, grid_mission: mission)
      create(:grid_item, :in_inventory, grid_hackr: runner, name: "Glowstick")
      create(:grid_mining_rig, grid_hackr: runner)
      log_in!(admin)

      get "/root/grid_hackrs/#{runner.id}"

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("// IDENTITY //", "// VITALS //", "// LOCATION //", "// ECONOMY //", "// BREACH //", "// LOADOUT //",
        "// INVENTORY · 1 / ", "// MINING RIG //", "// REPUTATION //", "// MISSIONS · 1 ACTIVE //", "// FEATURES //")
      expect(body).to include("Runner", "Pixel Den", "Arcade Row", "Neon Flats", "Glowstick", "NO ACTIVE BREACH", "INACTIVE")
      expect(body).to include("data-command=\"01\" href=\"/root/grid_hackr_missions/#{assignment.id}\"", "Signal Run")
      expect(body).to include("data-command=\"items\" href=\"/root/grid_hackrs/#{runner.id}/items\"")
      expect(body).not_to include("// DEV TOOLS //", "[SANDBOX]", "[RESET 2FA]")

      dev_tools!(true)
      get "/root/grid_hackrs/#{runner.id}"
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("// DEV TOOLS //", "DEV TOOLS ON", "data-command=\"rig\" href=\"/root/grid_hackrs/#{runner.id}/mining_rig\"",
        "data-command=\"sandbox\" href=\"/root/grid_breach_sandbox/new?hackr_id=#{runner.id}\"")
      # The hackr's own SANDBOX link comes before the generic destination row, so the command opens this hackr's sandbox.
      expect(body.index("data-command=\"sandbox\" href=\"/root/grid_breach_sandbox/new?hackr_id=#{runner.id}\"")).to be < body.index("data-command=\"sandbox\" href=\"/root/grid_breach_sandbox/new\"")
    end

    it "resets 2FA from the IDENTITY row and lands back on the inspector" do
      runner.update!(otp_required_for_login: true, otp_secret: ROTP::Base32.random)
      log_in!(admin)

      get "/root/grid_hackrs/#{runner.id}"
      body = response.body
      expect(body).to include("ENABLED", "[RESET 2FA]")
      expect(body[%r{<form[^>]*action="/root/grid/hackrs/#{runner.id}/reset_totp"[^>]*>}]).to include('data-confirm="Disable 2FA for Runner?')

      post "/root/grid/hackrs/#{runner.id}/reset_totp"
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}")
      follow_redirect!
      expect(response.body).to include("[OK]", "2FA disabled for Runner.")
      expect(runner.reload.otp_required_for_login?).to be(false)

      post "/root/grid/hackrs/#{runner.id}/reset_totp"
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}")
      follow_redirect!
      expect(response.body).to include("[ERR]", "does not have 2FA enabled")
    end
  end

  describe "the stat editor" do
    it "is refused without dev tools" do
      log_in!(admin)
      get "/root/grid_hackrs/#{runner.id}/edit_stats"

      expect(response).to redirect_to("/root")
    end

    it "writes the named stats, syncing clearance from XP" do
      dev_tools!(true)
      log_in!(admin)

      get "/root/grid_hackrs/#{runner.id}/edit_stats"
      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("// STATS //", "// RAW JSON //", "DEV TOOLS ON", "[WRITE STATS]", "[WRITE RAW JSON]")
      %w[health energy psyche clearance xp inspiration bonus_inventory_slots govcorp_debt facility_alert_level].each do |key|
        expect(body).to include(%(name="stats[#{key}]"), %(for="stats_#{key}"))
      end
      expect(body).to include('<input type="hidden" name="stats[captured]" value="0">', 'name="raw_json"', 'data-confirm="Overwrite stats for Runner?"')

      patch "/root/grid_hackrs/#{runner.id}/update_stats", params: {stats: {health: "42", xp: "5000", clearance: "1", inspiration: "3", captured: "0"}}
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}/edit_stats")
      follow_redirect!
      expect(response.body).to include("[OK]", "Stats updated for Runner.")
      runner.reload
      expect(runner.stat("health")).to eq(42)
      expect(runner.stat("xp")).to eq(5000)
      expect(runner.stat("clearance")).to eq(runner.clearance_for_xp(5000))
      expect(runner.stat("inspiration")).to eq(3)
    end

    it "keeps an ALERT LEVEL edit on an uncaptured hackr and clears it only on a release from containment" do
      dev_tools!(true)
      log_in!(admin)

      patch "/root/grid_hackrs/#{runner.id}/update_stats", params: {stats: {facility_alert_level: "50", captured: "0"}}
      expect(runner.reload.stat("facility_alert_level")).to eq(50)

      runner.update_column(:stats, runner.stats.merge("captured" => true, "captured_origin_room_id" => room.id))
      patch "/root/grid_hackrs/#{runner.id}/update_stats", params: {stats: {facility_alert_level: "50", captured: "0"}}
      runner.reload
      expect(runner.stat("captured")).to be(false)
      expect(runner.stat("facility_alert_level")).to eq(0)
      expect(runner.stat("captured_origin_room_id")).to be_nil
    end

    it "writes raw JSON and refuses text that is not a JSON object, re-rendering it as typed" do
      dev_tools!(true)
      log_in!(admin)

      patch "/root/grid_hackrs/#{runner.id}/update_stats", params: {raw_json: '{"health": 7, "xp": 0}'}
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}/edit_stats")
      expect(runner.reload.stats).to eq({"health" => 7, "xp" => 0})

      patch "/root/grid_hackrs/#{runner.id}/update_stats", params: {raw_json: '{"health": 7,'}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to be_console_clean
      expect(response.body).to include("[ERR]", "Invalid JSON", "{&quot;health&quot;: 7,")

      patch "/root/grid_hackrs/#{runner.id}/update_stats", params: {raw_json: "[1, 2]"}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("[ERR]", "must be a JSON object")
      expect(runner.reload.stats).to eq({"health" => 7, "xp" => 0})

      patch "/root/grid_hackrs/#{runner.id}/update_stats", params: {raw_json: ""}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("[ERR]", "Invalid JSON")
      expect(runner.reload.stats).to eq({"health" => 7, "xp" => 0})
    end
  end

  describe "the warp" do
    let!(:target) { create(:grid_room, grid_zone: zone, name: "Back Alley") }

    it "renders the ROOM picker and warps the hackr" do
      dev_tools!(true)
      log_in!(admin)

      get "/root/grid_hackrs/#{runner.id}/warp"
      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("// NOW //", "// DESTINATION //", "Pixel Den", 'id="warp-form"', 'id="warp-input"', 'id="warp-hidden"', 'name="room_id"',
        'id="warp-dropdown"', 'id="warp-status"', "AdminCombobox.init", "Back Alley")

      post "/root/grid_hackrs/#{runner.id}/perform_warp", params: {room_id: target.id}
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}")
      follow_redirect!
      expect(response.body).to include("[OK]", "Runner warped to Back Alley (Arcade Row).")
      expect(runner.reload.current_room).to eq(target)
    end

    it "refuses an unknown room and a hackr in a BREACH with a 422" do
      dev_tools!(true)
      log_in!(admin)

      post "/root/grid_hackrs/#{runner.id}/perform_warp", params: {room_id: 0}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to be_console_clean
      expect(response.body).to include("[ERR]", "Room not found.")

      create(:grid_hackr_breach, grid_hackr: runner)
      post "/root/grid_hackrs/#{runner.id}/perform_warp", params: {room_id: target.id}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("[ERR]", "active BREACH in progress", "IN PROGRESS")
      expect(runner.reload.current_room).to eq(room)
    end
  end

  describe "the rig manager" do
    it "sends a hackr without a rig back to the inspector" do
      dev_tools!(true)
      log_in!(admin)

      get "/root/grid_hackrs/#{runner.id}/mining_rig"
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}")
      follow_redirect!
      expect(response.body).to include("[ERR]", "Runner has no mining rig.")
    end

    it "reads the rig, force-installs and uninstalls a part, every force action confirming" do
      dev_tools!(true)
      rig = create(:grid_mining_rig, grid_hackr: runner)
      part = create(:grid_item, :component, :in_inventory, grid_hackr: runner, name: "Hash Chip")
      log_in!(admin)

      get "/root/grid_hackrs/#{runner.id}/mining_rig"
      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("// RIG //", "// SLOTS //", "// COMPONENTS · 0 //", "// FORCE INSTALL //", "MOTHERBOARD", "INF", "INACTIVE", "Hash Chip", 'name="item_id"')
      expect(body[%r{<form[^>]*action="/root/grid_hackrs/#{runner.id}/force_activate_rig"[^>]*>}]).to include('data-confirm="Force-activate Runner')

      post "/root/grid_hackrs/#{runner.id}/force_install_component", params: {item_id: part.id}
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}/mining_rig")
      follow_redirect!
      body = response.body
      expect(body).to include("[OK]", "Force-installed Hash Chip", "// COMPONENTS · 1 //", "[UNINSTALL]")
      expect(body[%r{<form[^>]*action="/root/grid_hackrs/#{runner.id}/force_uninstall_component\?item_id=#{part.id}"[^>]*>}]).to include("data-confirm=\"Force-uninstall Hash Chip")
      expect(part.reload.grid_mining_rig).to eq(rig)

      post "/root/grid_hackrs/#{runner.id}/force_uninstall_component", params: {item_id: part.id}
      follow_redirect!
      expect(response.body).to include("[OK]", "Force-uninstalled Hash Chip")
      expect(part.reload.grid_hackr).to eq(runner)
    end
  end
end
