require "rails_helper"

# /root/grid_mission_arcs — the arcs ledger and the arc record (its
# missions as a ledger) as console screens (console-ui-for-all-admin
# Phase 4, 2026-11-01).
RSpec.describe "Admin grid mission arcs", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_mission_arcs"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the arcs as numbered ledger rows with destinations and the prompt" do
    arc = create(:grid_mission_arc, name: "The Fracture", slug: "the-fracture", position: 1, published: true)
    create(:grid_mission, grid_mission_arc: arc)
    create(:grid_mission_arc, name: "Ghost Signals", slug: "ghost-signals", position: 2, published: false)
    log_in!(admin)

    get "/root/grid_mission_arcs"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 arcs", "1 mission in arcs", "1 live", "LIVE", "DRAFT")
    expect(body).to include("[01]", "[02]", 'data-command="02"', "/root/grid_mission_arcs/the-fracture/edit", "/root/grid_mission_arcs/the-fracture/history")
    expect(body).to include("[MISSIONS]", "[WIZARD]")
    expect(body).not_to include("[ARCS]")
    expect(body).to include("type an arc number")
  end

  it "redirects show to the record screen" do
    arc = create(:grid_mission_arc, slug: "the-fracture")
    log_in!(admin)

    get "/root/grid_mission_arcs/#{arc.slug}"

    expect(response).to redirect_to("/root/grid_mission_arcs/the-fracture/edit")
  end

  it "renders the record with the fields, its missions, [+] NEW MISSION prefilled and the delete form" do
    arc = create(:grid_mission_arc, name: "The Fracture", slug: "the-fracture")
    mission = create(:grid_mission, grid_mission_arc: arc, name: "First Contact", slug: "first-contact")
    log_in!(admin)

    get "/root/grid_mission_arcs/the-fracture/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="The Fracture"', 'action="/root/grid_mission_arcs/the-fracture"')
    %w[slug name position published description].each { |field| expect(body).to include(%(name="grid_mission_arc[#{field}]")) }
    expect(body).to include("// MISSIONS //", "First Contact", "/root/grid_missions/#{mission.slug}/edit", "/root/grid_missions/new?grid_mission_arc_id=#{arc.id}")
    expect(body).to include('form="delete-arc"', 'id="delete-arc"', "type a mission number")
  end

  it "saves every field and stays on the record" do
    arc = create(:grid_mission_arc, slug: "old-slug")
    log_in!(admin)

    patch "/root/grid_mission_arcs/old-slug", params: {grid_mission_arc: {slug: "new-slug", name: "Renamed", description: "D", position: "7", published: "0"}}

    expect(response).to redirect_to("/root/grid_mission_arcs/new-slug/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Mission arc 'Renamed' updated."))
    expect(arc.reload).to have_attributes(slug: "new-slug", name: "Renamed", description: "D", position: 7, published: false)
  end

  it "rejects a blank name with a 422, the error on the field and the form still on the stored slug" do
    create(:grid_mission_arc, slug: "the-fracture")
    log_in!(admin)

    patch "/root/grid_mission_arcs/the-fracture", params: {grid_mission_arc: {name: "", slug: "moved"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "can&#39;t be blank", 'action="/root/grid_mission_arcs/the-fracture"')
  end

  it "creates an arc and opens its record; deletes it and keeps its missions" do
    log_in!(admin)

    post "/root/grid_mission_arcs", params: {grid_mission_arc: {slug: "fresh", name: "Fresh", position: "1", published: "1"}}
    arc = GridMissionArc.find_by!(slug: "fresh")
    expect(response).to redirect_to("/root/grid_mission_arcs/fresh/edit")
    mission = create(:grid_mission, grid_mission_arc: arc)

    expect { delete "/root/grid_mission_arcs/fresh" }.to change(GridMissionArc, :count).by(-1)
    expect(response).to redirect_to("/root/grid_mission_arcs")
    expect(mission.reload.grid_mission_arc_id).to be_nil
  end
end
