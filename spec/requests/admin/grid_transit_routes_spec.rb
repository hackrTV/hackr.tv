require "rails_helper"

# /root/grid_transit_routes — the local routes ledger and the route record
# (+ its stops) as console screens (console-ui-for-all-admin Phase 3,
# 2026-10-31).
RSpec.describe "Admin grid transit routes", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:region) { create(:grid_region, name: "Lakeshore") }
  let!(:zone) { create(:grid_zone, grid_region: region, name: "Docks") }
  let!(:type) { create(:grid_transit_type, name: "Metro") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_transit_routes"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the routes as numbered ledger rows with destinations and the prompt" do
    route = create(:grid_transit_route, grid_transit_type: type, grid_region: region, name: "Red Line", slug: "red-line", loop_route: true)
    create(:grid_transit_stop, grid_transit_route: route, grid_room: create(:grid_room, grid_zone: zone))
    create(:grid_transit_route, grid_transit_type: type, grid_region: region, active: false)
    log_in!(admin)

    get "/root/grid_transit_routes"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 routes", "1 active", "1 stop", "[01]", "[02]", 'data-command="02"', "Metro", "Lakeshore", "LOOP", "LINE", "OFF")
    expect(body).to include("/root/grid_transit_routes/red-line/edit", "/root/grid_transit_routes/red-line/history")
    expect(body).to include("[TRANSIT]", "[JOURNEYS]")
    expect(body).not_to include("[ROUTES]")
    expect(body).to include("type a route number")
  end

  it "redirects show to the record screen" do
    create(:grid_transit_route, slug: "red-line")
    log_in!(admin)

    get "/root/grid_transit_routes/red-line"

    expect(response).to redirect_to("/root/grid_transit_routes/red-line/edit")
  end

  it "renders the record with the fields, the stops, the add-stop picker and the delete form" do
    route = create(:grid_transit_route, grid_transit_type: type, grid_region: region, name: "Red Line", slug: "red-line")
    platform = create(:grid_room, grid_zone: zone, name: "Platform A", room_type: "transit")
    create(:grid_transit_stop, grid_transit_route: route, grid_room: platform, position: 0, label: "Docks", is_terminus: true)
    log_in!(admin)

    get "/root/grid_transit_routes/red-line/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Red Line"', 'action="/root/grid_transit_routes/red-line"', 'name="grid_transit_route[grid_transit_type_id]"', 'name="grid_transit_route[loop_route]"')
    expect(body).to include("// STOPS · 1 //", "[0]", "Docks", "Docks / Platform A", "TERMINUS", "/root/grid_transit_routes/red-line/remove_stop?stop_id=", 'data-confirm="Remove stop')
    expect(body).to include("// ADD STOP //", 'id="add-stop-form"', 'name="grid_transit_stop[grid_room_id]" id="stop-room-hidden"', 'id="stop-room-status"', "1 transit room")
    expect(body).to include("formId: 'add-stop-form'", "statusId: 'stop-room-status'", '"name":"Platform A"')
    expect(body).to include('form="delete-route"', 'id="delete-route"')
  end

  it "adds and removes a stop" do
    route = create(:grid_transit_route, grid_transit_type: type, grid_region: region, slug: "red-line")
    platform = create(:grid_room, grid_zone: zone, room_type: "transit")
    log_in!(admin)

    post "/root/grid_transit_routes/red-line/add_stop", params: {grid_transit_stop: {grid_room_id: platform.id, label: "Docks", is_terminus: "1"}}
    expect(response).to redirect_to("/root/grid_transit_routes/red-line/edit")
    stop = route.grid_transit_stops.sole
    expect(stop).to have_attributes(grid_room_id: platform.id, label: "Docks", is_terminus: true, position: 0)

    expect { delete "/root/grid_transit_routes/red-line/remove_stop", params: {stop_id: stop.id} }.to change(GridTransitStop, :count).by(-1)
  end

  it "saves every field and stays on the record" do
    route = create(:grid_transit_route, grid_transit_type: type, grid_region: region, slug: "red-line")
    other_type = create(:grid_transit_type)
    other_region = create(:grid_region)
    log_in!(admin)

    patch "/root/grid_transit_routes/red-line", params: {grid_transit_route: {name: "Blue Line", slug: "blue-line", grid_transit_type_id: other_type.id, grid_region_id: other_region.id,
                                                                              loop_route: "1", active: "0", description: "D", position: "3"}}

    expect(response).to redirect_to("/root/grid_transit_routes/blue-line/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Transit route 'Blue Line' updated."))
    expect(route.reload).to have_attributes(name: "Blue Line", slug: "blue-line", grid_transit_type_id: other_type.id, grid_region_id: other_region.id,
      loop_route: true, active: false, description: "D", position: 3)
  end

  it "rejects a blank slug with a 422 against the saved slug" do
    create(:grid_transit_route, name: "Red Line", slug: "red-line")
    log_in!(admin)

    patch "/root/grid_transit_routes/red-line", params: {grid_transit_route: {slug: ""}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "can&#39;t be blank", 'action="/root/grid_transit_routes/red-line"', '<h1 class="console-bar-title">Red Line</h1>')
  end

  it "creates a route and opens its record; deletes one" do
    log_in!(admin)

    get "/root/grid_transit_routes/new"
    expect(response.body).to be_console_clean

    post "/root/grid_transit_routes", params: {grid_transit_route: {name: "Fresh", slug: "fresh", grid_transit_type_id: type.id, grid_region_id: region.id, active: "1"}}
    expect(response).to redirect_to("/root/grid_transit_routes/fresh/edit")

    expect { delete "/root/grid_transit_routes/fresh" }.to change(GridTransitRoute, :count).by(-1)
    expect(response).to redirect_to("/root/grid_transit_routes")
  end
end
