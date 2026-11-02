require "rails_helper"

# /root/grid_breach_templates — the BREACH templates ledger and the
# template record as console screens (console-ui-for-all-admin Phase 4,
# 2026-11-01).
RSpec.describe "Admin grid breach templates", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_breach_templates"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the templates as numbered ledger rows with the filter, destinations and the prompt" do
    template = create(:grid_breach_template, name: "Vault Lock", slug: "vault-lock", tier: "elite", zone_slugs: ["docks"], position: 1)
    create(:grid_breach_template, :unpublished, name: "Drafty", slug: "drafty", position: 2)
    create(:grid_hackr_breach, grid_breach_template: template)
    log_in!(admin)

    get "/root/grid_breach_templates"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 templates", "1 live", "1 active breach")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="vault lock vault-lock elite docks"')
    expect(body).to include("ELITE", "LIVE", "DRAFT")
    expect(body).to include("/root/grid_breach_templates/vault-lock/edit", "/root/grid_breach_templates/vault-lock/history")
    expect(body).to include("[ENCOUNTERS]", "[ITEMS]")
    expect(body).not_to include("[BREACH]")
    expect(body).to include("type a template number")
  end

  it "renders the record with the fields, the JSON, its encounters and the delete form" do
    template = create(:grid_breach_template, name: "Vault Lock", slug: "vault-lock", zone_slugs: ["docks", "arcade"])
    room = create(:grid_room, name: "Pier 9")
    create(:grid_breach_encounter, grid_breach_template: template, grid_room: room, state: "cooldown")
    log_in!(admin)

    get "/root/grid_breach_templates/vault-lock/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Vault Lock"', 'action="/root/grid_breach_templates/vault-lock"', 'value="docks, arcade"')
    expect(body).to include('name="grid_breach_template[pnr_threshold]"', 'name="grid_breach_template[zone_slugs_csv]"', 'name="grid_breach_template[published]"')
    expect(body).to include("// PROTOCOL COMPOSITION (JSON) //", "&quot;type&quot;: &quot;trace&quot;", "// REWARD TABLE (JSON) //")
    expect(body).to include("// ENCOUNTERS //", "Pier 9", "COOLDOWN", "/root/grid_breach_encounters/new?grid_breach_template_id=#{template.id}")
    expect(body).to include('form="delete-template"', 'id="delete-template"')
  end

  it "saves every field and stays on the record" do
    template = create(:grid_breach_template, slug: "vault-lock")
    log_in!(admin)

    patch "/root/grid_breach_templates/vault-lock", params: {grid_breach_template: {
      name: "Vault Lock II", slug: "vault-lock-ii", description: "D", tier: "advanced", min_clearance: "12",
      pnr_threshold: "80", base_detection_rate: "7", cooldown_min: "60", cooldown_max: "120", xp_reward: "250",
      cred_reward: "90", requires_mission_slug: "the-heist", requires_item_slug: "keycard", danger_level_min: "3",
      published: "0", position: "9", zone_slugs_csv: "docks, arcade",
      protocol_composition_json: '[{"type": "trace", "count": 2}]', reward_table_json: '{"bonus": 1}'
    }}

    expect(response).to redirect_to("/root/grid_breach_templates/vault-lock-ii/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Breach template 'Vault Lock II' updated."))
    expect(template.reload).to have_attributes(name: "Vault Lock II", slug: "vault-lock-ii", description: "D", tier: "advanced",
      min_clearance: 12, pnr_threshold: 80, base_detection_rate: 7, cooldown_min: 60, cooldown_max: 120, xp_reward: 250,
      cred_reward: 90, requires_mission_slug: "the-heist", requires_item_slug: "keycard", danger_level_min: 3,
      published: false, position: 9, zone_slugs: ["docks", "arcade"],
      protocol_composition: [{"type" => "trace", "count" => 2}], reward_table: {"bonus" => 1})
  end

  it "rejects invalid JSON with a 422, the [ERR] reply and the JSON as typed" do
    template = create(:grid_breach_template, slug: "vault-lock")
    log_in!(admin)

    patch "/root/grid_breach_templates/vault-lock", params: {grid_breach_template: {name: "X", protocol_composition_json: "[{oops"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "Invalid JSON", "[{oops", 'action="/root/grid_breach_templates/vault-lock"')
    expect(template.reload.name).not_to eq("X")
  end

  it "rejects an out-of-range PNR with a 422 and the error on the field" do
    create(:grid_breach_template, slug: "vault-lock")
    log_in!(admin)

    patch "/root/grid_breach_templates/vault-lock", params: {grid_breach_template: {pnr_threshold: "101", slug: "renamed"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "must be in 1..100", 'action="/root/grid_breach_templates/vault-lock"')
  end

  it "creates a template and opens its record; deletes one without breaches" do
    log_in!(admin)

    get "/root/grid_breach_templates/new"
    expect(response.body).to be_console_clean
    expect(response.body).to include("[CREATE TEMPLATE]")

    post "/root/grid_breach_templates", params: {grid_breach_template: {
      name: "Fresh", slug: "fresh", tier: "standard",
      min_clearance: "0", pnr_threshold: "75", base_detection_rate: "5", cooldown_min: "0", cooldown_max: "0",
      xp_reward: "0", cred_reward: "0", danger_level_min: "0", position: "1", zone_slugs_csv: "",
      protocol_composition_json: "[]", reward_table_json: "{}"
    }}
    expect(response).to redirect_to("/root/grid_breach_templates/fresh/edit")

    expect { delete "/root/grid_breach_templates/fresh" }.to change(GridBreachTemplate, :count).by(-1)
    expect(response).to redirect_to("/root/grid_breach_templates")
  end

  it "refuses to delete a template still placed in a room" do
    template = create(:grid_breach_template, slug: "vault-lock", name: "Vault Lock")
    create(:grid_breach_encounter, grid_breach_template: template)
    log_in!(admin)

    expect { delete "/root/grid_breach_templates/vault-lock" }.not_to change(GridBreachTemplate, :count)
    expect(response).to redirect_to("/root/grid_breach_templates")
    follow_redirect!
    expect(response.body).to include("[ERR]", "Cannot delete")
  end
end
