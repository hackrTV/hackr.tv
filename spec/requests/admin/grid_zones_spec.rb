require "rails_helper"

# /root/grid_zones — the zones ledger and the zone record as console
# screens (console-ui-for-all-admin Phase 3, 2026-10-31).
RSpec.describe "Admin grid zones", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:region) { create(:grid_region, name: "Lakeshore") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_zones"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the zones as numbered ledger rows with the filter, destinations and the prompt" do
    faction = create(:grid_faction, name: "Fracture")
    playlist = ZonePlaylist.create!(name: "Docks Ambient", slug: "docks-ambient", crossfade_duration_ms: 4000, default_volume: 0.4)
    zone = create(:grid_zone, grid_region: region, grid_faction: faction, ambient_playlist: playlist, name: "Docks", slug: "docks", danger_level: 4)
    create(:grid_room, grid_zone: zone)
    create(:grid_zone, grid_region: region, name: "Arcade", slug: "arcade")
    log_in!(admin)

    get "/root/grid_zones"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 zones", "1 room", "1 dangerous")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="docks docks lakeshore fracture docks ambient"')
    expect(body).to include("/root/grid_zones/#{zone.id}/edit", "/root/grid_zones/#{zone.id}/history")
    expect(body).to include("[REGIONS]", "[ROOMS]")
    expect(body).not_to include("[ZONES]")
    expect(body).to include("type a zone number")
  end

  it "redirects show to the record screen" do
    zone = create(:grid_zone, grid_region: region)
    log_in!(admin)

    get "/root/grid_zones/#{zone.id}"

    expect(response).to redirect_to("/root/grid_zones/#{zone.id}/edit")
  end

  it "renders the record with the fields, its rooms, the region link and the delete form" do
    zone = create(:grid_zone, grid_region: region, name: "Docks")
    create(:grid_room, grid_zone: zone, name: "Pier 9", room_type: "hub", min_clearance: 5)
    log_in!(admin)

    get "/root/grid_zones/#{zone.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Docks"', "action=\"/root/grid_zones/#{zone.id}\"", 'name="grid_zone[grid_region_id]"', 'name="grid_zone[danger_level]"')
    expect(body).to include("[&gt;] LAKESHORE", "/root/grid_regions/#{region.id}/edit")
    expect(body).to include("// ROOMS //", "Pier 9", "HUB", "CL 5", "/root/grid_rooms/new?grid_zone_id=#{zone.id}")
    expect(body).to include('form="delete-zone"', 'id="delete-zone"')
  end

  it "prefills the region of a new zone" do
    log_in!(admin)

    get "/root/grid_zones/new", params: {grid_region_id: region.id}

    expect(response.body).to be_console_clean
    expect(response.body).to include(%(<option selected="selected" value="#{region.id}">Lakeshore</option>))
  end

  it "saves every field and stays on the record" do
    zone = create(:grid_zone, grid_region: region)
    other = create(:grid_region)
    faction = create(:grid_faction)
    playlist = ZonePlaylist.create!(name: "Sprawl", slug: "sprawl", crossfade_duration_ms: 4000, default_volume: 0.4)
    log_in!(admin)

    patch "/root/grid_zones/#{zone.id}", params: {grid_zone: {name: "Docks", slug: "docks", description: "D", danger_level: "3",
                                                              grid_region_id: other.id, grid_faction_id: faction.id, ambient_playlist_id: playlist.id}}

    expect(response).to redirect_to("/root/grid_zones/#{zone.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Zone 'Docks' updated."))
    expect(zone.reload).to have_attributes(name: "Docks", slug: "docks", description: "D", danger_level: 3,
      grid_region_id: other.id, grid_faction_id: faction.id, ambient_playlist_id: playlist.id)
  end

  it "rejects an out-of-range danger level with a 422 and the error on the field" do
    zone = create(:grid_zone, grid_region: region, name: "Docks")
    log_in!(admin)

    patch "/root/grid_zones/#{zone.id}", params: {grid_zone: {danger_level: "11"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "must be in 0..10")
  end

  it "creates a zone and opens its record; deletes one without rooms" do
    log_in!(admin)

    post "/root/grid_zones", params: {grid_zone: {name: "Fresh", slug: "fresh", grid_region_id: region.id, danger_level: "0"}}
    zone = GridZone.find_by!(slug: "fresh")
    expect(response).to redirect_to("/root/grid_zones/#{zone.id}/edit")

    expect { delete "/root/grid_zones/#{zone.id}" }.to change(GridZone, :count).by(-1)
    expect(response).to redirect_to("/root/grid_zones")
  end
end
