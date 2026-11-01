require "rails_helper"

# /root/grid_rooms — the rooms ledger and the room record as console
# screens (console-ui-for-all-admin Phase 3, 2026-10-31).
RSpec.describe "Admin grid rooms", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:region) { create(:grid_region, name: "Lakeshore") }
  let!(:zone) { create(:grid_zone, grid_region: region, name: "Docks") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_rooms"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the rooms as numbered ledger rows with the filter, destinations and the prompt" do
    room = create(:grid_room, grid_zone: zone, name: "Pier 9", slug: "pier-9", room_type: "hub", min_clearance: 5)
    create(:grid_room, grid_zone: zone, name: "Warehouse", room_type: "standard")
    log_in!(admin)

    get "/root/grid_rooms"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 rooms", "1 zone")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="pier 9 pier-9 docks lakeshore hub"', "STANDARD")
    expect(body).to include("/root/grid_rooms/#{room.id}/edit", "/root/grid_rooms/#{room.id}/history")
    expect(body).to include("[ZONES]", "[EXITS]")
    expect(body).not_to include("[ROOMS]")
    expect(body).to include("type a room number")
  end

  it "redirects show to the record screen" do
    room = create(:grid_room, grid_zone: zone)
    log_in!(admin)

    get "/root/grid_rooms/#{room.id}"

    expect(response).to redirect_to("/root/grid_rooms/#{room.id}/edit")
  end

  it "renders the record with the fields, the zone picker, its exits and mobs, and the delete form" do
    room = create(:grid_room, grid_zone: zone, name: "Pier 9", slug: "pier-9")
    other = create(:grid_room, grid_zone: zone, name: "Warehouse")
    way = GridExit.create!(from_room: room, to_room: other, direction: "north", locked: true)
    mob = create(:grid_mob, grid_room: room, name: "Dockhand", mob_type: "lore")
    log_in!(admin)

    get "/root/grid_rooms/#{room.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Pier 9"', 'value="pier-9"', "action=\"/root/grid_rooms/#{room.id}\"", 'name="grid_room[room_type]"', "// DESCRIPTION //")
    expect(body).to include(%(name="grid_room[grid_zone_id]" id="zone-cb-hidden" value="#{zone.id}"), 'value="Lakeshore / Docks"', 'id="zone-cb-dropdown"')
    expect(body).to include("// EXITS //", "NORTH", "LOCKED", "/root/grid_exits/#{way.id}/edit", "/root/grid_exits/new?from_room_id=#{room.id}")
    expect(body).to include("// MOBS //", "Dockhand", "LORE", "/root/grid_mobs/#{mob.id}/edit", 'data-command="02"')
    expect(body).to include("[&gt;] DOCKS", 'form="delete-room"', 'id="delete-room"')
    expect(body).to include("AdminCombobox.init", "getElementById('grid_room_slug')")
  end

  it "prefills the zone of a new room" do
    log_in!(admin)

    get "/root/grid_rooms/new", params: {grid_zone_id: zone.id}

    expect(response.body).to be_console_clean
    expect(response.body).to include(%(id="zone-cb-hidden" value="#{zone.id}"), 'value="Lakeshore / Docks"')
  end

  it "saves every field and stays on the record" do
    room = create(:grid_room, grid_zone: zone)
    other_zone = create(:grid_zone, grid_region: region)
    playlist = ZonePlaylist.create!(name: "Sprawl", slug: "sprawl", crossfade_duration_ms: 4000, default_volume: 0.4)
    log_in!(admin)

    patch "/root/grid_rooms/#{room.id}", params: {grid_room: {name: "Pier 9", slug: "pier-9", description: "D", room_type: "shop",
                                                              min_clearance: "7", grid_zone_id: other_zone.id, ambient_playlist_id: playlist.id}}

    expect(response).to redirect_to("/root/grid_rooms/#{room.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Room 'Pier 9' updated."))
    expect(room.reload).to have_attributes(name: "Pier 9", slug: "pier-9", description: "D", room_type: "shop", min_clearance: 7,
      grid_zone_id: other_zone.id, ambient_playlist_id: playlist.id)
  end

  it "rejects a negative clearance with a 422 and the error on the field" do
    room = create(:grid_room, grid_zone: zone, name: "Pier 9")
    log_in!(admin)

    patch "/root/grid_rooms/#{room.id}", params: {grid_room: {min_clearance: "-1"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "must be greater than or equal to 0", '<h1 class="console-bar-title">Pier 9</h1>')
  end

  it "creates a room and opens its record; deletes one" do
    log_in!(admin)

    post "/root/grid_rooms", params: {grid_room: {name: "Fresh", slug: "fresh", grid_zone_id: zone.id, room_type: "standard", min_clearance: "0"}}
    room = GridRoom.find_by!(slug: "fresh")
    expect(response).to redirect_to("/root/grid_rooms/#{room.id}/edit")

    expect { delete "/root/grid_rooms/#{room.id}" }.to change(GridRoom, :count).by(-1)
    expect(response).to redirect_to("/root/grid_rooms")
  end
end
