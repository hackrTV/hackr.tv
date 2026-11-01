require "rails_helper"

# /root/grid_mobs — the mobs ledger and the mob record (avatar, dialogue
# tree and vendor config editors, a vendor's shop listings) as console
# screens (console-ui-for-all-admin Phase 3, 2026-10-31).
RSpec.describe "Admin grid mobs", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:zone) { create(:grid_zone, name: "Docks") }
  let!(:room) { create(:grid_room, grid_zone: zone, name: "Pier 9") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  # .env sets ADMIN_DEV_TOOLS=true for local work; the gate is off here
  # unless an example turns it on.
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return(nil)
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_mobs"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the mobs as numbered ledger rows with the filter, destinations and the prompt" do
    faction = create(:grid_faction, name: "Fracture")
    mob = create(:grid_mob, :vendor, grid_room: room, grid_faction: faction, name: "Dockhand")
    create(:grid_mob, grid_room: room, name: "Ghost")
    log_in!(admin)

    get "/root/grid_mobs"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 mobs", "1 vendors")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="dockhand vendor pier 9 docks fracture"', "Docks / Pier 9", "VENDOR", "Fracture")
    expect(body).to include("/root/grid_mobs/#{mob.id}/edit", "/root/grid_mobs/#{mob.id}/history")
    expect(body).not_to include("[TEST]")
    expect(body).to include("[ROOMS]", "[STARTS]")
    expect(body).not_to include("[MOBS]")
    expect(body).to include("type a mob number")
  end

  it "links the NPC tester from the ledger and the record while dev tools are on" do
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return("true")
    mob = create(:grid_mob, grid_room: room)
    log_in!(admin)

    get "/root/grid_mobs"
    expect(response.body).to include("[TEST]", "/root/grid_npc_dialogue_tester/new?mob_id=#{mob.id}")

    get "/root/grid_mobs/#{mob.id}/edit"
    expect(response.body).to include("[TEST]", "/root/grid_npc_dialogue_tester/new?mob_id=#{mob.id}")
  end

  it "redirects show to the record screen" do
    mob = create(:grid_mob, grid_room: room)
    log_in!(admin)

    get "/root/grid_mobs/#{mob.id}"

    expect(response).to redirect_to("/root/grid_mobs/#{mob.id}/edit")
  end

  it "renders the record with the fields, the room picker, both editors' hooks and the delete form" do
    mob = create(:grid_mob, grid_room: room, name: "Dockhand", dialogue_tree: {"greeting" => "Hey.", "topics" => {"job" => {"response" => "Lift."}}})
    log_in!(admin)

    get "/root/grid_mobs/#{mob.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Dockhand"', "action=\"/root/grid_mobs/#{mob.id}\"", 'id="mob-form"', 'for="grid_mob_mob_type"', 'id="grid_mob_mob_type"', "// DESCRIPTION //")
    expect(body).to include(%(name="grid_mob[grid_room_id]" id="room-cb-hidden" value="#{room.id}"), 'value="Docks / Pier 9"', 'id="room-cb-dropdown"')
    expect(body).to include("// DIALOGUE TREE //", 'name="grid_mob[dialogue_tree_json]" id="dialogue-tree-hidden"', "&quot;greeting&quot;:&quot;Hey.&quot;")
    expect(body).to include('id="dialogue-mode-structured"', 'id="dialogue-mode-raw"', 'id="dialogue-structured"', 'id="dialogue-greeting"', 'id="dialogue-topics-root"',
      'id="dialogue-add-root-topic"', 'id="dialogue-raw"', 'id="dialogue-raw-textarea"', 'id="dialogue-raw-error"')
    expect(body).to include("// VENDOR CONFIG //", 'name="grid_mob[vendor_config_json]" id="vendor-config-hidden"', 'id="vendor-mode-structured"', 'id="vendor-mode-raw"',
      'id="vendor-structured"', 'id="vendor-shop-type"', 'id="vendor-restock-hours"', 'id="vendor-rotation-wrap"', 'id="vendor-rotation-count"',
      'id="vendor-raw"', 'id="vendor-raw-textarea"', 'id="vendor-raw-error"')
    expect(body).to include("NO AVATAR", "[^] UPLOAD AVATAR", 'name="grid_mob[avatar]"')
    expect(body).not_to include("// SHOP LISTINGS //")
    expect(body).to include("[&gt;] ROOM", 'form="delete-mob"', 'id="delete-mob"', 'id="purge-avatar"')
    expect(body).to include("getElementById('mob-form')", "AdminCombobox.init", '"name":"Pier 9"')
    script = body[/<script[^>]*>\s*\(function\(\) \{\s*\/\/ === Dialogue Tree Editor.*?<\/script>/m]
    expect(script).to include("'rc-btn'", "'[+] SUB'").and(satisfy { |s| !s.include?("tui-") && !s.include?("cssText") }) # the editor builds console rows
  end

  it "saves every field with the editors' JSON and stays on the record" do
    mob = create(:grid_mob, grid_room: room)
    other = create(:grid_room, grid_zone: zone)
    faction = create(:grid_faction)
    log_in!(admin)

    patch "/root/grid_mobs/#{mob.id}", params: {grid_mob: {name: "Dockhand", description: "D", mob_type: "vendor", grid_room_id: other.id, grid_faction_id: faction.id,
                                                           dialogue_tree_json: '{"greeting":"Hey."}', vendor_config_json: '{"shop_type":"black_market","rotation_count":4}'}}

    expect(response).to redirect_to("/root/grid_mobs/#{mob.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Mob 'Dockhand' updated."))
    expect(mob.reload).to have_attributes(name: "Dockhand", description: "D", mob_type: "vendor", grid_room_id: other.id, grid_faction_id: faction.id,
      dialogue_tree: {"greeting" => "Hey."}, vendor_config: {"shop_type" => "black_market", "rotation_count" => 4})
  end

  it "rejects a blank name with a 422 and the error on the field" do
    mob = create(:grid_mob, grid_room: room, name: "Dockhand")
    log_in!(admin)

    patch "/root/grid_mobs/#{mob.id}", params: {grid_mob: {name: "", dialogue_tree_json: "{}", vendor_config_json: "{}"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "can&#39;t be blank", '<h1 class="console-bar-title">Dockhand</h1>')
  end

  it "refuses malformed editor JSON with a 422 and keeps the stored tree and config" do
    mob = create(:grid_mob, grid_room: room, name: "Dockhand", dialogue_tree: {"greeting" => "Hey."}, vendor_config: {"shop_type" => "standard"})
    log_in!(admin)

    patch "/root/grid_mobs/#{mob.id}", params: {grid_mob: {name: "Renamed", dialogue_tree_json: '{"greeting":"Yo",}', vendor_config_json: "{"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "Dialogue tree is not valid JSON", "Vendor config is not valid JSON")
    expect(mob.reload).to have_attributes(name: "Dockhand", dialogue_tree: {"greeting" => "Hey."}, vendor_config: {"shop_type" => "standard"})

    expect {
      post "/root/grid_mobs", params: {grid_mob: {name: "Fresh", grid_room_id: room.id, dialogue_tree_json: "{oops", vendor_config_json: "{}"}}
    }.not_to change(GridMob, :count)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "shows a missing room's error in the ROOM picker row" do
    log_in!(admin)

    post "/root/grid_mobs", params: {grid_mob: {name: "Fresh", grid_room_id: "", dialogue_tree_json: "{}", vendor_config_json: "{}"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to match(%r{id="room-cb-status">[^<]*</span>\s*<span class="rc-err">[^<]*must exist</span>})
  end

  it "shows a vendor's listings and adds and removes one" do
    mob = create(:grid_mob, :vendor, grid_room: room, name: "Dockhand")
    listing = create(:grid_shop_listing, :unlimited, grid_mob: mob, base_price: 120, rotation_pool: true)
    item = create(:grid_item_definition, name: "Wrench")
    log_in!(admin)

    get "/root/grid_mobs/#{mob.id}/edit"
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("// SHOP LISTINGS //", listing.name, "INF", "ACTIVE", "ROT", "/root/grid_shop_listings/#{listing.id}/edit")
    expect(body).to include("/root/grid_mobs/#{mob.id}/remove_listing?listing_id=#{listing.id}", 'data-confirm="Remove listing')
    expect(body).to include("// ADD LISTING //", "Wrench [", "/root/grid_shop_listings?mob_id=#{mob.id}")

    post "/root/grid_mobs/#{mob.id}/add_listing", params: {grid_shop_listing: {grid_item_definition_id: item.id, base_price: "40", stock: "", min_clearance: "2"}}
    expect(response).to redirect_to("/root/grid_mobs/#{mob.id}/edit")
    expect(mob.grid_shop_listings.find_by(grid_item_definition: item)).to have_attributes(base_price: 40, stock: nil, min_clearance: 2)

    expect { delete "/root/grid_mobs/#{mob.id}/remove_listing", params: {listing_id: listing.id} }.to change(GridShopListing, :count).by(-1)
  end

  it "shows the avatar with its remove control and purges it" do
    mob = create(:grid_mob, grid_room: room, name: "Dockhand")
    mob.avatar.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_cover.jpg")), filename: "a.jpg", content_type: "image/jpeg")
    log_in!(admin)

    get "/root/grid_mobs/#{mob.id}/edit"
    expect(response.body).to include("[^] REPLACE AVATAR", 'form="purge-avatar"', 'class="cc-art-img"')

    delete "/root/grid_mobs/#{mob.id}/purge_avatar"
    expect(response).to redirect_to("/root/grid_mobs/#{mob.id}/edit")
    expect(mob.reload.avatar).not_to be_attached
  end

  it "creates a mob and opens its record; deletes one" do
    log_in!(admin)

    get "/root/grid_mobs/new"
    expect(response.body).to be_console_clean

    post "/root/grid_mobs", params: {grid_mob: {name: "Fresh", grid_room_id: room.id, dialogue_tree_json: "", vendor_config_json: ""}}
    mob = GridMob.find_by!(name: "Fresh")
    expect(response).to redirect_to("/root/grid_mobs/#{mob.id}/edit")

    expect { delete "/root/grid_mobs/#{mob.id}" }.to change(GridMob, :count).by(-1)
    expect(response).to redirect_to("/root/grid_mobs")
  end
end
