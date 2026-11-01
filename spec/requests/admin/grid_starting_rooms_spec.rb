require "rails_helper"

# /root/grid_starting_rooms — the starting rooms ledger and the start
# record as console screens (console-ui-for-all-admin Phase 3,
# 2026-10-31).
RSpec.describe "Admin grid starting rooms", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:region) { create(:grid_region, name: "Lakeshore") }
  let!(:zone) { create(:grid_zone, grid_region: region, name: "Docks") }
  let!(:room) { create(:grid_room, grid_zone: zone, name: "Pier 9") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_starting_rooms"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the starts as numbered ledger rows with destinations and the prompt" do
    start = GridStartingRoom.create!(grid_room: room, name: "The Docks", blurb: "Salt air.", position: 1, active: true)
    GridStartingRoom.create!(grid_room: create(:grid_room, grid_zone: zone), name: "Off", blurb: "B", position: 2, active: false)
    log_in!(admin)

    get "/root/grid_starting_rooms"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 starting rooms", "1 offered at graduation")
    expect(body).to include("[01]", "[02]", 'data-command="02"', "Docks / Pier 9", "Lakeshore", "POS 1", "LIVE", "OFF")
    expect(body).to include("/root/grid_starting_rooms/#{start.id}/edit", "/root/grid_starting_rooms/#{start.id}/history")
    expect(body).to include("[ROOMS]", "[MOBS]")
    expect(body).not_to include("[STARTS]")
    expect(body).to include("type a start number")
  end

  it "renders the record with the fields, the room picker bound to the form and the delete form" do
    start = GridStartingRoom.create!(grid_room: room, name: "The Docks", blurb: "Salt air.", position: 1, active: true)
    log_in!(admin)

    get "/root/grid_starting_rooms/#{start.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="The Docks"', 'id="starting-room-form"', "action=\"/root/grid_starting_rooms/#{start.id}\"", "// BLURB //", "Salt air.")
    expect(body).to include(%(name="grid_starting_room[grid_room_id]" id="room-cb-hidden" value="#{room.id}"), 'value="Lakeshore / Docks / Pier 9"')
    expect(body).to include("formId: 'starting-room-form'", "submitError: 'Select a room first'")
    expect(body).to include('form="delete-start"', 'id="delete-start"', "/root/grid_rooms/#{room.id}/edit")
  end

  it "saves every field and stays on the record" do
    start = GridStartingRoom.create!(grid_room: room, name: "The Docks", blurb: "Salt air.", position: 1, active: true)
    other = create(:grid_room, grid_zone: zone)
    log_in!(admin)

    patch "/root/grid_starting_rooms/#{start.id}", params: {grid_starting_room: {name: "Pier", grid_room_id: other.id, blurb: "B", position: "4", active: "0"}}

    expect(response).to redirect_to("/root/grid_starting_rooms/#{start.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Starting room 'Pier' updated."))
    expect(start.reload).to have_attributes(name: "Pier", grid_room_id: other.id, blurb: "B", position: 4, active: false)
  end

  it "rejects a blank blurb with a 422 and the error under it" do
    start = GridStartingRoom.create!(grid_room: room, name: "The Docks", blurb: "Salt air.", position: 1, active: true)
    log_in!(admin)

    patch "/root/grid_starting_rooms/#{start.id}", params: {grid_starting_room: {blurb: ""}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "can&#39;t be blank", '<h1 class="console-bar-title">The Docks</h1>')
  end

  it "creates a start and opens its record; deletes one" do
    log_in!(admin)

    get "/root/grid_starting_rooms/new"
    expect(response.body).to be_console_clean

    post "/root/grid_starting_rooms", params: {grid_starting_room: {name: "Fresh", grid_room_id: room.id, blurb: "B", position: "1", active: "1"}}
    start = GridStartingRoom.find_by!(name: "Fresh")
    expect(response).to redirect_to("/root/grid_starting_rooms/#{start.id}/edit")

    expect { delete "/root/grid_starting_rooms/#{start.id}" }.to change(GridStartingRoom, :count).by(-1)
    expect(response).to redirect_to("/root/grid_starting_rooms")
  end
end
