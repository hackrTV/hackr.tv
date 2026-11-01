require "rails_helper"

# /root/grid_exits — the exits ledger and the exit record as console
# screens (console-ui-for-all-admin Phase 3, 2026-10-31).
RSpec.describe "Admin grid exits", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:zone) { create(:grid_zone, name: "Docks") }
  let!(:pier) { create(:grid_room, grid_zone: zone, name: "Pier 9") }
  let!(:warehouse) { create(:grid_room, grid_zone: zone, name: "Warehouse") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_exits"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the exits as numbered ledger rows with the filter, destinations and the prompt" do
    way = GridExit.create!(from_room: pier, to_room: warehouse, direction: "north", locked: true)
    GridExit.create!(from_room: warehouse, to_room: pier, direction: "south")
    log_in!(admin)

    get "/root/grid_exits"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 exits", "1 locked")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="pier 9 docks north warehouse docks locked"', "NORTH", "LOCKED", "OPEN")
    expect(body).to include("/root/grid_exits/#{way.id}/edit", "/root/grid_exits/#{way.id}/history")
    expect(body).to include("[ROOMS]", "[MOBS]")
    expect(body).not_to include("[EXITS]")
    expect(body).to include("type an exit number")
  end

  it "redirects show to the record screen" do
    way = GridExit.create!(from_room: pier, to_room: warehouse, direction: "north")
    log_in!(admin)

    get "/root/grid_exits/#{way.id}"

    expect(response).to redirect_to("/root/grid_exits/#{way.id}/edit")
  end

  it "renders the record with the rooms, a diagonal direction kept as typed, and the delete form" do
    way = GridExit.create!(from_room: pier, to_room: warehouse, direction: "northeast")
    log_in!(admin)

    get "/root/grid_exits/#{way.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("Pier 9 &gt; NORTHEAST &gt; Warehouse", "action=\"/root/grid_exits/#{way.id}\"")
    expect(body).to include('name="grid_exit[direction]"', 'value="northeast"', 'list="exit-directions"', '<datalist id="exit-directions">')
    expect(body).to include(%(<option selected="selected" value="#{pier.id}">Docks — Pier 9</option>), %(<option selected="selected" value="#{warehouse.id}">Docks — Warehouse</option>))
    expect(body).to include("/root/grid_rooms/#{pier.id}/edit", "/root/grid_rooms/#{warehouse.id}/edit")
    expect(body).to include('form="delete-exit"', 'id="delete-exit"')
  end

  it "prefills the room of a new exit" do
    log_in!(admin)

    get "/root/grid_exits/new", params: {from_room_id: pier.id}

    expect(response.body).to be_console_clean
    expect(response.body).to include(%(<option selected="selected" value="#{pier.id}">Docks — Pier 9</option>))
  end

  it "saves every field and stays on the record" do
    way = GridExit.create!(from_room: pier, to_room: warehouse, direction: "north")
    log_in!(admin)

    patch "/root/grid_exits/#{way.id}", params: {grid_exit: {from_room_id: warehouse.id, to_room_id: pier.id, direction: "up", locked: "1"}}

    expect(response).to redirect_to("/root/grid_exits/#{way.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", "Exit updated.")
    expect(way.reload).to have_attributes(from_room_id: warehouse.id, to_room_id: pier.id, direction: "up", locked: true)
  end

  it "rejects a malformed direction with a 422 and the error on the field" do
    way = GridExit.create!(from_room: pier, to_room: warehouse, direction: "north")
    log_in!(admin)

    patch "/root/grid_exits/#{way.id}", params: {grid_exit: {direction: "North West"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "must be lowercase alphanumeric with hyphens", "Pier 9 &gt; NORTH &gt; Warehouse")
  end

  it "creates an exit and opens its record; deletes one" do
    log_in!(admin)

    post "/root/grid_exits", params: {grid_exit: {from_room_id: pier.id, to_room_id: warehouse.id, direction: "west", locked: "0"}}
    way = GridExit.find_by!(direction: "west")
    expect(response).to redirect_to("/root/grid_exits/#{way.id}/edit")
    follow_redirect!
    expect(response.body).to include("Exit created: Pier 9 &gt; west &gt; Warehouse")

    expect { delete "/root/grid_exits/#{way.id}" }.to change(GridExit, :count).by(-1)
    expect(response).to redirect_to("/root/grid_exits")
  end
end
