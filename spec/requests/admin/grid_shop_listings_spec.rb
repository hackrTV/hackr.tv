require "rails_helper"

# /root/grid_shop_listings — the shops ledger and the listing record as
# console screens (console-ui-for-all-admin Phase 4, 2026-11-01).
RSpec.describe "Admin grid shop listings", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:vendor) { create(:grid_mob, :vendor, name: "Rook") }
  let!(:item) { create(:grid_item_definition, name: "Stim Pack", item_type: "consumable", rarity: "rare") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_shop_listings"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists every listing as numbered ledger rows with the VENDOR row, the filter, destinations and the prompt" do
    listing = create(:grid_shop_listing, grid_mob: vendor, grid_item_definition: item, base_price: 1500, stock: 0, max_stock: 4, rotation_pool: true)
    create(:grid_shop_listing, :unlimited, grid_mob: create(:grid_mob, :vendor, name: "Vex"))
    log_in!(admin)

    get "/root/grid_shop_listings"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 listings", "2 vendors", "1 sold out")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"', 'data-search="stim pack rook consumable rare"')
    expect(body).to include("1,500", "0/4", "INF", "ROT", "RARE")
    expect(body).to include("/root/grid_shop_listings/#{listing.id}/edit", "/root/grid_shop_listings/#{listing.id}/history", "/root/grid_shop_listings/#{listing.id}/restock", "[RESTOCK]")
    expect(body).to include("/root/grid_shop_listings?mob_id=#{vendor.id}", "[&gt;] SALES", "[ITEMS]", "[SALES]")
    expect(body).not_to include("[SHOPS]")
    expect(body).to include("type a listing number")
  end

  it "narrows to one vendor, prefills the vendor of a new listing, and reads an unknown vendor unfiltered" do
    create(:grid_shop_listing, grid_mob: vendor, grid_item_definition: item)
    create(:grid_shop_listing, grid_mob: create(:grid_mob, :vendor, name: "Vex"), grid_item_definition: create(:grid_item_definition, name: "Data Shard"))
    log_in!(admin)

    get "/root/grid_shop_listings", params: {mob_id: vendor.id}
    expect(response.body).to include("Stim Pack", "/root/grid_shop_listings/new?grid_mob_id=#{vendor.id}", "/root/grid_mobs/#{vendor.id}/edit")
    expect(response.body).not_to include("Data Shard")

    get "/root/grid_shop_listings", params: {mob_id: "0"}
    expect(response.body).to include("Stim Pack", "Data Shard")

    get "/root/grid_shop_listings/new", params: {grid_mob_id: vendor.id}
    expect(response.body).to be_console_clean
    expect(response.body).to include(%(<option selected="selected" value="#{vendor.id}">))
  end

  it "redirects show to the record screen" do
    listing = create(:grid_shop_listing, grid_mob: vendor, grid_item_definition: item)
    log_in!(admin)

    get "/root/grid_shop_listings/#{listing.id}"

    expect(response).to redirect_to("/root/grid_shop_listings/#{listing.id}/edit")
  end

  it "renders the record with the fields, the vendor / item links and the delete form" do
    listing = create(:grid_shop_listing, grid_mob: vendor, grid_item_definition: item, base_price: 300)
    log_in!(admin)

    get "/root/grid_shop_listings/#{listing.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("Stim Pack", 'value="300"', "action=\"/root/grid_shop_listings/#{listing.id}\"", "NEXT RESTOCK")
    expect(body).to include('name="grid_shop_listing[grid_mob_id]"', 'name="grid_shop_listing[restock_interval_hours]"', 'name="grid_shop_listing[rotation_pool]"')
    expect(body).to include("/root/grid_mobs/#{vendor.id}/edit", "/root/grid_item_definitions/#{item.slug}/edit", "/root/grid_shop_listings?mob_id=#{vendor.id}")
    expect(body).to include('form="delete-listing"', 'id="delete-listing"')
  end

  it "saves every field and stays on the record" do
    listing = create(:grid_shop_listing, grid_mob: vendor, grid_item_definition: item)
    other_vendor = create(:grid_mob, :vendor)
    other_item = create(:grid_item_definition)
    log_in!(admin)

    patch "/root/grid_shop_listings/#{listing.id}", params: {grid_shop_listing: {
      grid_mob_id: other_vendor.id, grid_item_definition_id: other_item.id, base_price: "250", sell_price: "90",
      stock: "3", max_stock: "6", restock_amount: "2", restock_interval_hours: "12", active: "0", rotation_pool: "1", min_clearance: "5"
    }}

    expect(response).to redirect_to("/root/grid_shop_listings/#{listing.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]")
    expect(listing.reload).to have_attributes(grid_mob_id: other_vendor.id, grid_item_definition_id: other_item.id, base_price: 250, sell_price: 90,
      stock: 3, max_stock: 6, restock_amount: 2, restock_interval_hours: 12, active: false, rotation_pool: true, min_clearance: 5)
  end

  it "rejects a negative stock with a 422 and the error on the field" do
    listing = create(:grid_shop_listing, grid_mob: vendor, grid_item_definition: item)
    log_in!(admin)

    patch "/root/grid_shop_listings/#{listing.id}", params: {grid_shop_listing: {stock: "-1"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to be_console_clean
    expect(response.body).to include("[ERR]", "rc-err", "greater than or equal to 0")
  end

  it "creates a listing and opens its record, restocks it on the ledger, deletes it through the hidden form" do
    log_in!(admin)

    post "/root/grid_shop_listings", params: {grid_shop_listing: {grid_mob_id: vendor.id, grid_item_definition_id: item.id, base_price: "100",
                                                                  stock: "0", max_stock: "5", restock_amount: "1", restock_interval_hours: "24", min_clearance: "0"}}
    listing = GridShopListing.last
    expect(response).to redirect_to("/root/grid_shop_listings/#{listing.id}/edit")

    post "/root/grid_shop_listings/#{listing.id}/restock"
    expect(response).to redirect_to("/root/grid_shop_listings?mob_id=#{vendor.id}")
    expect(listing.reload.stock).to eq(5)

    expect { delete "/root/grid_shop_listings/#{listing.id}" }.to change(GridShopListing, :count).by(-1)
    expect(response).to redirect_to("/root/grid_shop_listings?mob_id=#{vendor.id}")
  end
end
