require "rails_helper"

# /root/grid_transit_types — the transit types ledger and the type record
# as console screens (console-ui-for-all-admin Phase 3, 2026-10-31).
RSpec.describe "Admin grid transit types", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_transit_types"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the types as numbered ledger rows with destinations and the prompt" do
    create(:grid_transit_type, name: "Metro", slug: "metro", category: "public", base_fare: 5, icon_key: "TRAIN", position: 1)
    create(:grid_transit_type, :private_type, name: "Cab", slug: "cab", published: false, position: 2)
    log_in!(admin)

    get "/root/grid_transit_types"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 transit types", "1 live", "[01]", "[02]", 'data-command="02"', "PUBLIC", "PRIVATE", "TRAIN", "LIVE", "DRAFT")
    expect(body).to include("/root/grid_transit_types/metro/edit", "/root/grid_transit_types/metro/history")
    expect(body).to include("[ROUTES]", "[JOURNEYS]")
    expect(body).not_to include("[TRANSIT]")
    expect(body).to include("type a type number")
  end

  it "renders the record with the fields, its routes and the delete form" do
    type = create(:grid_transit_type, name: "Metro", slug: "metro")
    route = create(:grid_transit_route, grid_transit_type: type, name: "Red Line")
    log_in!(admin)

    get "/root/grid_transit_types/metro/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Metro"', 'action="/root/grid_transit_types/metro"', 'name="grid_transit_type[category]"', 'name="grid_transit_type[icon_key]"', "// DESCRIPTION //")
    expect(body).to include("// ROUTES //", "Red Line", "/root/grid_transit_routes/#{route.slug}/edit")
    expect(body).to include('form="delete-type"', 'id="delete-type"', 'action="/root/grid_transit_types/metro"')
  end

  it "saves every field and stays on the record" do
    type = create(:grid_transit_type, slug: "metro")
    log_in!(admin)

    patch "/root/grid_transit_types/metro", params: {grid_transit_type: {name: "Night Bus", slug: "night-bus", category: "private", description: "D", icon_key: "BUS",
                                                                         base_fare: "12", min_clearance: "3", published: "1", position: "4"}}

    expect(response).to redirect_to("/root/grid_transit_types/night-bus/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Transit type 'Night Bus' updated."))
    expect(type.reload).to have_attributes(name: "Night Bus", slug: "night-bus", category: "private", description: "D", icon_key: "BUS",
      base_fare: 12, min_clearance: 3, published: true, position: 4)
  end

  it "rejects a bad save with a 422 against the saved slug" do
    create(:grid_transit_type, name: "Metro", slug: "metro")
    log_in!(admin)

    patch "/root/grid_transit_types/metro", params: {grid_transit_type: {slug: "", base_fare: "-1"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "must be greater than or equal to 0", 'action="/root/grid_transit_types/metro"', '<h1 class="console-bar-title">Metro</h1>')
  end

  it "creates a type and opens its record; deletes one (the delete was a dead link before)" do
    log_in!(admin)

    get "/root/grid_transit_types/new"
    expect(response.body).to be_console_clean

    post "/root/grid_transit_types", params: {grid_transit_type: {name: "Fresh", slug: "fresh", category: "public", base_fare: "0", min_clearance: "0"}}
    expect(response).to redirect_to("/root/grid_transit_types/fresh/edit")

    expect { delete "/root/grid_transit_types/fresh" }.to change(GridTransitType, :count).by(-1)
    expect(response).to redirect_to("/root/grid_transit_types")
  end
end
