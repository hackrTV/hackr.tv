require "rails_helper"

# /root/grid_hackrs/:hackr_id/items — a hackr's items, grant and remove,
# as a console screen (console-ui-for-all-admin Phase 5, 2026-11-01).
RSpec.describe "Admin grid hackr items", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:runner) { create(:grid_hackr, hackr_alias: "Runner") }
  let!(:definition) { create(:grid_item_definition, name: "Glowstick") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def wear!(hackr, name)
    gear = create(:grid_item_definition, :gear, name: name)
    create(:grid_item, :in_inventory, grid_item_definition: gear, grid_hackr: hackr).tap { |item| item.update!(equipped_slot: "head") }
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_hackrs/#{runner.id}/items"

    expect(response).not_to have_http_status(:ok)
  end

  it "renders the GRANT picker, the equipped gear and the inventory with a confirming [REMOVE]" do
    held = create(:grid_item, :in_inventory, grid_hackr: runner, name: "Signal Flare", quantity: 3)
    wear!(runner, "Mirror Shades")
    log_in!(admin)

    get "/root/grid_hackrs/#{runner.id}/items"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("// GRANT //", "// EQUIPPED · 1 //", "// INVENTORY · 1 / ", "1 equipped", "HEAD", "Mirror Shades", "Signal Flare")
    expect(body).to include('id="grant-form"', 'id="grant-input"', 'id="grant-hidden"', 'name="definition_id"', 'id="grant-dropdown"', 'id="grant-status"',
      'name="quantity"', "AdminCombobox.init", "Glowstick")
    expect(body[%r{<form[^>]*action="/root/grid_hackrs/#{runner.id}/items/#{held.id}"[^>]*>}]).to include('data-confirm="Remove Signal Flare (x3) from Runner?"')
    expect(body).to include("data-command=\"back\" href=\"/root/grid_hackrs/#{runner.id}\"", "[ROOT]")
  end

  it "grants an item and removes one, refusing an unknown definition and an equipped item" do
    log_in!(admin)

    post "/root/grid_hackrs/#{runner.id}/items/grant", params: {definition_id: definition.id, quantity: 2}
    expect(response).to redirect_to("/root/grid_hackrs/#{runner.id}/items")
    follow_redirect!
    expect(response.body).to include("[OK]", "Granted 2x Glowstick to Runner.")
    item = runner.grid_items.find_by!(grid_item_definition: definition)

    post "/root/grid_hackrs/#{runner.id}/items/grant", params: {definition_id: 0}
    follow_redirect!
    expect(response.body).to include("[ERR]", "Item definition not found.")

    worn = wear!(runner, "Mirror Shades")
    delete "/root/grid_hackrs/#{runner.id}/items/#{worn.id}"
    follow_redirect!
    expect(response.body).to include("[ERR]", "Cannot remove equipped item")
    expect(GridItem.exists?(worn.id)).to be(true)

    delete "/root/grid_hackrs/#{runner.id}/items/#{item.id}"
    follow_redirect!
    expect(response.body).to include("[OK]", "Removed Glowstick from Runner.")
    expect(GridItem.exists?(item.id)).to be(false)
  end
end
