require "rails_helper"

# The dev-tool testers — the BREACH sandbox, the NPC dialogue tester and
# the PAC escape tester — as console screens (console-ui-for-all-admin
# Phase 5, 2026-11-01): a start screen with pickers, then a terminal that
# keeps its own > input (the page prompt is omitted) and whose command
# JSON is unchanged.
RSpec.describe "Admin grid testers", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let(:zone) { create(:grid_zone, name: "Arcade Row") }
  let(:room) { create(:grid_room, grid_zone: zone, name: "Pixel Den") }
  let!(:runner) { create(:grid_hackr, hackr_alias: "Runner", current_room: room, zone_entry_room: room) }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def dev_tools!(on)
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return(on ? "true" : nil)
  end

  # The terminal screens' output pane holds the game's own HTML (inline
  # colours, by design); the console around it is what must be clean.
  def terminal_chrome(body)
    body.split('class="rc-term-out"', 2).first + body.split('id="command-section"', 2).last
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    dev_tools!(true)
  end

  it "refuses every tester without dev tools" do
    dev_tools!(false)
    log_in!(admin)

    get "/root/grid_breach_sandbox/new?hackr_id=#{runner.id}"
    expect(response).to redirect_to("/root")
    get "/root/grid_npc_dialogue_tester/new"
    expect(response).to redirect_to("/root")
    get "/root/grid_pac_escape_tester/new"
    expect(response).to redirect_to("/root")
  end

  describe "the BREACH sandbox" do
    let!(:template) { create(:grid_breach_template, name: "Ice Wall") }

    def equip_deck!(hackr)
      deck_def = create(:grid_item_definition, :gear, slug: "test-deck", name: "Test Deck",
        properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
      create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr).tap { |deck| deck.update!(equipped_slot: "deck") }
    end

    it "opens without a hackr (the SANDBOX destination) on a HACKR picker, and with one on its DECK" do
      log_in!(admin)

      get "/root/grid_breach_sandbox/new"
      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("BREACH SANDBOX", "DEV TOOLS ON", "// HACKR //", "// TEMPLATE //", 'id="sandbox-form"', 'name="hackr_id"', 'id="hackr-hidden" value=""',
        'name="template_id"', 'id="sandbox-input"', 'id="sandbox-hidden"', 'id="sandbox-status"', "Ice Wall", "Runner", "[START SANDBOX]")
      expect(body).not_to include("[&lt;] INSPECTOR", "[SANDBOX]")

      equip_deck!(runner)
      get "/root/grid_breach_sandbox/new?hackr_id=#{runner.id}"
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include(%(id="hackr-hidden" value="#{runner.id}"), "Runner (CL ", "DECK", "Test Deck", "[&lt;] INSPECTOR")
    end

    it "refuses a start without a hackr, a template or a DECK with a 422" do
      log_in!(admin)

      post "/root/grid_breach_sandbox", params: {template_id: template.id}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to be_console_clean
      expect(response.body).to include("[ERR]", "Hackr is required.")

      post "/root/grid_breach_sandbox", params: {hackr_id: runner.id, template_id: 0}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("[ERR]", "Template not found.")

      post "/root/grid_breach_sandbox", params: {hackr_id: runner.id, template_id: template.id}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("[ERR]", "Runner: No DECK equipped.", "none equipped")
      expect(response.body).to include(%(id="sandbox-hidden" value="#{template.id}"), "Selected: Ice Wall")
    end

    it "404s an unknown hackr id" do
      log_in!(admin)

      get "/root/grid_breach_sandbox/new?hackr_id=0"
      expect(response).to have_http_status(:not_found)
      get "/root/grid_npc_dialogue_tester/new?hackr_id=0"
      expect(response).to have_http_status(:not_found)
      get "/root/grid_pac_escape_tester/new?hackr_id=0"
      expect(response).to have_http_status(:not_found)
    end

    it "starts a sandbox, runs a command and aborts it" do
      equip_deck!(runner)
      log_in!(admin)

      post "/root/grid_breach_sandbox", params: {hackr_id: runner.id, template_id: template.id}
      breach = runner.grid_hackr_breaches.last
      expect(response).to redirect_to("/root/grid_breach_sandbox/#{breach.id}")
      follow_redirect!

      body = response.body
      expect(terminal_chrome(body)).to be_console_clean
      expect(body).to include("SANDBOX ##{breach.id}", "Runner", "Ice Wall", "// TERMINAL //", "[ABORT]", "[EXECUTE]", "SANDBOX BREACH ENDED")
      expect(body).to include('id="breach-output"', 'id="command-input"', 'id="send-btn"', 'id="command-section"', 'id="breach-ended"', 'id="abort-form"')
      expect(body).not_to include('data-controller="terminal"', "console-prompt")

      post "/root/grid_breach_sandbox/#{breach.id}/command", params: {input: "status"}, as: :json
      expect(response.parsed_body).to include("breach_active" => true)
      expect(response.parsed_body["output"]).to be_present

      delete "/root/grid_breach_sandbox/#{breach.id}/abort"
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}")
      follow_redirect!
      expect(response.body).to include("[OK]", "Sandbox breach aborted for Runner.")
      expect(breach.reload.active?).to be(false)
    end
  end

  describe "the NPC dialogue tester" do
    let(:mob_room) { create(:grid_room, grid_zone: zone, name: "Back Alley") }
    let!(:mob) { create(:grid_mob, grid_room: mob_room, name: "Fixer Vex") }

    it "opens on the HACKR and MOB pickers, prefilled from the query" do
      log_in!(admin)

      get "/root/grid_npc_dialogue_tester/new", params: {hackr_id: runner.id, mob_id: mob.id}
      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("NPC DIALOGUE TESTER", "// SESSION //", 'id="tester-form"', %(id="hackr-hidden" value="#{runner.id}"), %(id="mob-hidden" value="#{mob.id}"),
        "Arcade Row / Back Alley / Fixer Vex", 'id="mob-input"', 'id="mob-status"', "[START DIALOGUE TEST]", "[&gt;] MOBS", "[SANDBOX]", "[PAC]")
      expect(body).not_to include("[NPC]")

      post "/root/grid_npc_dialogue_tester", params: {hackr_id: runner.id}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to be_console_clean
      expect(response.body).to include("[ERR]", "Hackr and Mob are both required.")

      post "/root/grid_npc_dialogue_tester", params: {mob_id: mob.id}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(%(id="mob-hidden" value="#{mob.id}"), "Selected: Fixer Vex")
    end

    it "starts a session, runs a command and ends it" do
      log_in!(admin)

      post "/root/grid_npc_dialogue_tester", params: {hackr_id: runner.id, mob_id: mob.id}
      expect(response).to redirect_to("/root/grid_npc_dialogue_tester")
      follow_redirect!

      body = response.body
      expect(terminal_chrome(body)).to be_console_clean
      expect(body).to include("NPC TEST", "Fixer Vex", "Back Alley", "[END SESSION]", "[SEND]", "NPC DIALOGUE TEST ENDED")
      expect(body).to include('id="dialogue-output"', 'id="command-input"', 'id="send-btn"', 'id="command-section"', 'id="session-ended"', 'id="end-form"')
      expect(body[/<form[^>]*id="end-form"[^>]*>/]).to include("data-confirm=")
      expect(body).not_to include('data-controller="terminal"')

      post "/root/grid_npc_dialogue_tester/command", params: {input: "look"}, as: :json
      expect(response.parsed_body).to include("session_active" => true)

      delete "/root/grid_npc_dialogue_tester/finish"
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}")
      follow_redirect!
      expect(response.body).to include("[OK]", "NPC Dialogue Test ended.")
      expect(runner.reload.current_room).to eq(room)
    end
  end

  describe "the PAC escape tester" do
    it "opens on the HACKR picker with the hackr's room, and refuses a hackr with no PAC facility" do
      log_in!(admin)

      get "/root/grid_pac_escape_tester/new", params: {hackr_id: runner.id}
      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("PAC ESCAPE TESTER", "// HACKR //", "// OPTIONS //", 'id="pac-tester-form"', %(id="hackr-hidden" value="#{runner.id}"),
        "Pixel Den", 'name="impound"', "[CAPTURE INTO PAC]")
      expect(body).not_to include("[PAC]")

      post "/root/grid_pac_escape_tester", params: {}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("[ERR]", "Hackr is required.")

      post "/root/grid_pac_escape_tester", params: {hackr_id: runner.id}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to be_console_clean
      expect(response.body).to include("[ERR]", "No PAC facility")
    end

    it "opens the terminal on a started test and ends it" do
      allow_any_instance_of(Grid::PacEscapeTesterService).to receive(:start!)
      allow_any_instance_of(Grid::PacEscapeTesterService).to receive(:restore!)
      log_in!(admin)

      post "/root/grid_pac_escape_tester", params: {hackr_id: runner.id, impound: "1"}
      expect(response).to redirect_to("/root/grid_pac_escape_tester")
      follow_redirect!

      body = response.body
      expect(terminal_chrome(body)).to be_console_clean
      expect(body).to include("PAC TEST", "Runner", "Arcade Row / Pixel Den", "[END TEST]", "[EXECUTE]", 'id="escaped-badge"')
      expect(body).to include('id="pac-output"', 'id="command-input"', 'id="send-btn"', 'id="end-form"')

      post "/root/grid_pac_escape_tester/command", params: {input: "look"}, as: :json
      expect(response.parsed_body).to include("session_active" => true, "escaped" => true)

      delete "/root/grid_pac_escape_tester/finish"
      expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}")
      follow_redirect!
      expect(response.body).to include("[OK]", "PAC Escape Test ended.")
    end
  end
end
