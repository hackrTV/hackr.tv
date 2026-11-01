require "rails_helper"

# /root/grid_slipstream_routes — the slipstream ledger and the route
# record (+ its legs) as console screens (console-ui-for-all-admin
# Phase 3, 2026-10-31).
RSpec.describe "Admin grid slipstream routes", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:lakeshore) { create(:grid_region, name: "Lakeshore") }
  let!(:arch) { create(:grid_region, name: "The Arch") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_slipstream_routes"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the routes as numbered ledger rows with destinations and the prompt" do
    route = create(:grid_slipstream_route, origin_region: lakeshore, destination_region: arch, name: "Lake Run", slug: "lake-run")
    create(:grid_slipstream_leg, grid_slipstream_route: route)
    create(:grid_slipstream_route, active: false)
    log_in!(admin)

    get "/root/grid_slipstream_routes"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 slipstream routes", "1 active", "[01]", "[02]", 'data-command="02"', "Lake Run", "Lakeshore &gt; The Arch", "15%")
    expect(body).to include("/root/grid_slipstream_routes/lake-run/edit", "/root/grid_slipstream_routes/lake-run/history")
    expect(body).to include("[ROUTES]", "[JOURNEYS]")
    expect(body).not_to include("[SLIPSTREAM]")
    expect(body).to include("type a route number")
  end

  it "redirects show to the record screen" do
    create(:grid_slipstream_route, slug: "lake-run")
    log_in!(admin)

    get "/root/grid_slipstream_routes/lake-run"

    expect(response).to redirect_to("/root/grid_slipstream_routes/lake-run/edit")
  end

  it "renders the record with the fields, the legs and their forks, and the delete form" do
    route = create(:grid_slipstream_route, origin_region: lakeshore, destination_region: arch, name: "Lake Run", slug: "lake-run")
    create(:grid_slipstream_leg, grid_slipstream_route: route, position: 1, name: "Junction", breach_template_slug: "jx-gate")
    log_in!(admin)

    get "/root/grid_slipstream_routes/lake-run/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Lake Run"', 'action="/root/grid_slipstream_routes/lake-run"', 'name="grid_slipstream_route[origin_room_id]"', 'name="grid_slipstream_route[detection_risk_base]"')
    expect(body).to include("// RISK //", "// LEGS · 1 //", "Junction", "[A] Maintenance Corridor · risk -5", "[B] Freight Car · risk 10", "2 forks", "jx-gate")
    expect(body).to include('form="delete-route"', 'id="delete-route"')
  end

  it "saves every field and stays on the record" do
    route = create(:grid_slipstream_route, slug: "lake-run")
    board = create(:grid_room)
    arrive = create(:grid_room)
    log_in!(admin)

    patch "/root/grid_slipstream_routes/lake-run", params: {grid_slipstream_route: {name: "Arch Run", slug: "arch-run", origin_region_id: arch.id, destination_region_id: lakeshore.id,
                                                                                    origin_room_id: board.id, destination_room_id: arrive.id, description: "D",
                                                                                    min_clearance: "20", base_heat_cost: "12", detection_risk_base: "30", position: "2", active: "0"}}

    expect(response).to redirect_to("/root/grid_slipstream_routes/arch-run/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Slipstream route 'Arch Run' updated."))
    expect(route.reload).to have_attributes(name: "Arch Run", slug: "arch-run", origin_region_id: arch.id, destination_region_id: lakeshore.id,
      origin_room_id: board.id, destination_room_id: arrive.id, description: "D", min_clearance: 20, base_heat_cost: 12, detection_risk_base: 30, position: 2, active: false)
  end

  it "rejects an out-of-range risk with a 422 against the saved slug" do
    create(:grid_slipstream_route, name: "Lake Run", slug: "lake-run")
    log_in!(admin)

    patch "/root/grid_slipstream_routes/lake-run", params: {grid_slipstream_route: {slug: "", detection_risk_base: "101"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "must be in 0..100", 'action="/root/grid_slipstream_routes/lake-run"', '<h1 class="console-bar-title">Lake Run</h1>')
  end

  it "creates a route and opens its record; deletes one" do
    board = create(:grid_room)
    arrive = create(:grid_room)
    log_in!(admin)

    get "/root/grid_slipstream_routes/new"
    expect(response.body).to be_console_clean

    post "/root/grid_slipstream_routes", params: {grid_slipstream_route: {name: "Fresh", slug: "fresh", origin_region_id: lakeshore.id, destination_region_id: arch.id,
                                                                          origin_room_id: board.id, destination_room_id: arrive.id, min_clearance: "15", base_heat_cost: "10", detection_risk_base: "15", active: "1"}}
    expect(response).to redirect_to("/root/grid_slipstream_routes/fresh/edit")

    expect { delete "/root/grid_slipstream_routes/fresh" }.to change(GridSlipstreamRoute, :count).by(-1)
    expect(response).to redirect_to("/root/grid_slipstream_routes")
  end
end
