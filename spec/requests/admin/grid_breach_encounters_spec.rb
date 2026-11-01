require "rails_helper"

# /root/grid_breach_encounters — the encounters ledger and the encounter
# record as console screens (console-ui-for-all-admin Phase 4,
# 2026-11-01).
RSpec.describe "Admin grid breach encounters", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:zone) { create(:grid_zone, name: "Docks") }
  let!(:room) { create(:grid_room, grid_zone: zone, name: "Pier 9") }
  let!(:template) { create(:grid_breach_template, name: "Vault Lock", slug: "vault-lock", tier: "elite") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_breach_encounters"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the encounters as numbered ledger rows with the filter, [RESET], destinations and the prompt" do
    cooling = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room, state: "cooldown", cooldown_until: 5.minutes.from_now)
    create(:grid_breach_encounter, grid_breach_template: create(:grid_breach_template), grid_room: create(:grid_room, name: "Arcade"))
    log_in!(admin)

    get "/root/grid_breach_encounters"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 encounters", "1 available", "1 cooldown")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="pier 9 docks vault lock elite cooldown"')
    expect(body).to include("/root/grid_breach_encounters/#{cooling.id}/edit", "/root/grid_breach_encounters/#{cooling.id}/history")
    expect(body.scan("[RESET]").size).to eq(1)
    reset_form = body[%r{<form[^>]*action="/root/grid_breach_encounters/#{cooling.id}/make_available"[^>]*>}]
    expect(reset_form).to include('data-confirm="Reset this encounter to available?"')
    expect(body).to include("[BREACH]")
    expect(body).not_to include("[ENCOUNTERS]")
    expect(body).to include("type an encounter number")
  end

  it "renders the record with the placement, the links, the meta and the delete form" do
    encounter = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room, instance_seed: 42)
    log_in!(admin)

    get "/root/grid_breach_encounters/#{encounter.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("action=\"/root/grid_breach_encounters/#{encounter.id}\"", 'value="42"')
    expect(body).to include(%(<option selected="selected" value="#{template.id}">Vault Lock (ELITE)</option>))
    expect(body).to include(%(<option selected="selected" value="#{room.id}">Docks :: Pier 9</option>))
    expect(body).to include("[&gt;] TEMPLATE", "/root/grid_breach_templates/vault-lock/edit", "[&gt;] PIER 9", "/root/grid_rooms/#{room.id}/edit")
    expect(body).to include("// META //", "0 active")
    expect(body).to include('form="delete-encounter"', 'id="delete-encounter"')
  end

  it "keeps an unpublished template on its encounter's record" do
    draft = create(:grid_breach_template, :unpublished, name: "Drafty")
    encounter = create(:grid_breach_encounter, grid_breach_template: draft, grid_room: room)
    log_in!(admin)

    get "/root/grid_breach_encounters/#{encounter.id}/edit"

    expect(response.body).to include(%(<option selected="selected" value="#{draft.id}">Drafty (STANDARD)</option>))
  end

  it "prefills the template of a new encounter" do
    log_in!(admin)

    get "/root/grid_breach_encounters/new", params: {grid_breach_template_id: template.id}

    expect(response.body).to be_console_clean
    expect(response.body).to include(%(<option selected="selected" value="#{template.id}">Vault Lock (ELITE)</option>), "[PLACE ENCOUNTER]")
  end

  it "saves every field and stays on the record" do
    encounter = create(:grid_breach_encounter, grid_breach_template: template, grid_room: room)
    other_room = create(:grid_room)
    other_template = create(:grid_breach_template)
    log_in!(admin)

    patch "/root/grid_breach_encounters/#{encounter.id}", params: {grid_breach_encounter: {
      grid_breach_template_id: other_template.id, grid_room_id: other_room.id, state: "depleted", instance_seed: "7"
    }}

    expect(response).to redirect_to("/root/grid_breach_encounters/#{encounter.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", "Encounter updated.")
    expect(encounter.reload).to have_attributes(grid_breach_template_id: other_template.id, grid_room_id: other_room.id,
      state: "depleted", instance_seed: 7)
  end

  it "rejects a second placement of a template in the same room with a 422 and the error on the field" do
    create(:grid_breach_encounter, grid_breach_template: template, grid_room: room)
    log_in!(admin)

    post "/root/grid_breach_encounters", params: {grid_breach_encounter: {grid_breach_template_id: template.id, grid_room_id: room.id, state: "available"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "already placed in this room")
  end

  it "places an encounter and opens its record; resets and deletes one" do
    log_in!(admin)

    post "/root/grid_breach_encounters", params: {grid_breach_encounter: {grid_breach_template_id: template.id, grid_room_id: room.id, state: "cooldown"}}
    encounter = GridBreachEncounter.last
    expect(response).to redirect_to("/root/grid_breach_encounters/#{encounter.id}/edit")

    post "/root/grid_breach_encounters/#{encounter.id}/make_available"
    expect(response).to redirect_to("/root/grid_breach_encounters")
    expect(encounter.reload.state).to eq("available")

    expect { delete "/root/grid_breach_encounters/#{encounter.id}" }.to change(GridBreachEncounter, :count).by(-1)
    expect(response).to redirect_to("/root/grid_breach_encounters")
  end
end
