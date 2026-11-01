require "rails_helper"

# /root/grid_regions — the regions ledger and the region record as
# console screens (console-ui-for-all-admin Phase 3, 2026-10-31).
RSpec.describe "Admin grid regions", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_regions"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the regions as numbered ledger rows with zone counts, destinations and the prompt" do
    region = create(:grid_region, name: "Lakeshore", slug: "lakeshore", description: "The water's edge")
    create_list(:grid_zone, 2, grid_region: region)
    create(:grid_region, name: "The Arch", slug: "the-arch")
    log_in!(admin)

    get "/root/grid_regions"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 regions", "2 zones")
    expect(body).to include("[01]", "[02]", 'data-command="02"')
    expect(body).to include("Lakeshore", "lakeshore · The water&#39;s edge", "2 ZONES", "0 ZONES")
    expect(body).to include("/root/grid_regions/#{region.id}/edit", "/root/grid_regions/#{region.id}/history", "/root/grid_map_editor/region/#{region.id}")
    expect(body).to include("[ZONES]", "[ROOMS]", "[SLIPSTREAM]")
    expect(body).not_to include("[REGIONS]")
    expect(body).to include("type a region number")
  end

  it "redirects show to the record screen" do
    region = create(:grid_region)
    log_in!(admin)

    get "/root/grid_regions/#{region.id}"

    expect(response).to redirect_to("/root/grid_regions/#{region.id}/edit")
  end

  it "renders the record with the fields, the GOVCORP ROOMS pickers, the zones and the delete form" do
    region = create(:grid_region, name: "Lakeshore")
    zone = create(:grid_zone, grid_region: region, name: "Docks", danger_level: 3)
    cell = create(:grid_room, grid_zone: zone, name: "Cell 9")
    region.update!(containment_room: cell)
    log_in!(admin)

    get "/root/grid_regions/#{region.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Lakeshore"', "action=\"/root/grid_regions/#{region.id}\"", "// DESCRIPTION //", "// GOVCORP ROOMS //")
    expect(body).to include('name="grid_region[containment_room_id]" id="containment-room-hidden" value="' + cell.id.to_s + '"')
    expect(body).to include('id="containment-room-input" class="admin-combobox-input selected"', 'value="Lakeshore / Docks / Cell 9"')
    expect(body).to include('id="hospital-room-dropdown"', 'id="facility-bribe-exit-room-status"')
    expect(body).to include("// ZONES //", "Docks", "DANGER 3", "/root/grid_zones/new?grid_region_id=#{region.id}")
    expect(body).to include('form="delete-region"', 'id="delete-region"', 'data-confirm="Delete region')
    expect(body).to include("window.AdminCombobox", '"name":"Cell 9"')
  end

  it "saves every field and stays on the record" do
    region = create(:grid_region)
    zone = create(:grid_zone, grid_region: region)
    rooms = create_list(:grid_room, 6, grid_zone: zone)
    log_in!(admin)

    fields = GridRegion::ROOM_FK_FIELDS.zip(rooms.map(&:id)).to_h
    patch "/root/grid_regions/#{region.id}", params: {grid_region: {name: "Lakeshore", slug: "lakeshore", description: "D"}.merge(fields)}

    expect(response).to redirect_to("/root/grid_regions/#{region.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Region 'Lakeshore' updated."))
    expect(region.reload).to have_attributes(name: "Lakeshore", slug: "lakeshore", description: "D", **fields)
  end

  it "rejects a blank name with a 422 and the error on the field" do
    region = create(:grid_region, name: "Lakeshore")
    log_in!(admin)

    patch "/root/grid_regions/#{region.id}", params: {grid_region: {name: ""}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "can&#39;t be blank", "<h1 class=\"console-bar-title\">Lakeshore</h1>")
  end

  it "shows a GovCorp room from another region as an error on its own picker row" do
    region = create(:grid_region, name: "Lakeshore")
    stray = create(:grid_room, grid_zone: create(:grid_zone, grid_region: create(:grid_region)))
    log_in!(admin)

    patch "/root/grid_regions/#{region.id}", params: {grid_region: {cell_block_room_id: stray.id}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to match(%r{id="cell-block-room-status">[^<]*</span>\s*<span class="rc-err">must be a room within this region})
    expect(response.body.scan('class="rc-err"').size).to eq(1)
  end

  it "creates a region and opens its record; deletes one without zones and refuses one with zones" do
    log_in!(admin)

    get "/root/grid_regions/new"
    expect(response.body).to be_console_clean

    post "/root/grid_regions", params: {grid_region: {name: "Fresh", slug: "fresh"}}
    region = GridRegion.find_by!(slug: "fresh")
    expect(response).to redirect_to("/root/grid_regions/#{region.id}/edit")

    kept = create(:grid_zone).grid_region
    delete "/root/grid_regions/#{kept.id}"
    follow_redirect!
    expect(response.body).to include("[ERR]", "zones still reference it")

    expect { delete "/root/grid_regions/#{region.id}" }.to change(GridRegion, :count).by(-1)
    expect(response).to redirect_to("/root/grid_regions")
  end
end
