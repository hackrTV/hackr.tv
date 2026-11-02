require "rails_helper"

# /root/grid_shop_transactions — the shop transaction log as a console
# ledger (console-ui-for-all-admin Phase 4, 2026-11-01).
RSpec.describe "Admin grid shop transactions", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, hackr_alias: "ghostline", password: "hackthegrid") }
  let!(:listing) { create(:grid_shop_listing, grid_item_definition: create(:grid_item_definition, name: "Stim Pack")) }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def record!(type, price, hackr: operative, burn: 0, recycle: 0)
    GridShopTransaction.create!(grid_hackr: hackr, grid_mob: listing.grid_mob, grid_shop_listing: listing,
      transaction_type: type, price_paid: price, burn_amount: burn, recycle_amount: recycle)
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_shop_transactions"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the transactions with the filter rows, destinations and the prompt" do
    record!("buy", 1200, burn: 120)
    record!("sell", 40, hackr: admin)
    log_in!(admin)

    get "/root/grid_shop_transactions"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 transactions", "1 buys", "1 sells", "// FILTER //", 'name="hackr_alias"', 'name="mob_id"')
    expect(body).to include("BUY", "SELL", "1,200", "120", "@ghostline", "Stim Pack", "/root/grid_shop_listings/#{listing.id}/edit")
    expect(body).to include("[SHOPS]", "[ITEMS]")
    expect(body).not_to include("[SALES]")
  end

  it "filters by hackr and TYPE, each keeping the other; an unknown type reads unfiltered" do
    record!("buy", 1200)
    record!("sell", 40)
    record!("buy", 77, hackr: admin)
    log_in!(admin)

    get "/root/grid_shop_transactions", params: {hackr_alias: "GhostLine", transaction_type: "buy"}
    body = response.body
    expect(body).to include("1 transaction", "1,200", "filtered")
    expect(body).not_to include(">40<", ">77<")
    expect(body).to include("/root/grid_shop_transactions?hackr_alias=GhostLine&amp;transaction_type=sell")
    expect(body).to match(/<input type="hidden" name="transaction_type"[^>]*value="buy"/)

    get "/root/grid_shop_transactions", params: {transaction_type: "refund"}
    expect(response.body).to include("3 transactions")
    expect(response.body).to include(%(class="rc-btn rc-btn--on" aria-current="page" href="/root/grid_shop_transactions"))
  end

  it "says so when no hackr has the alias" do
    record!("buy", 1200)
    log_in!(admin)

    get "/root/grid_shop_transactions", params: {hackr_alias: "nobody"}

    expect(response.body).to be_console_clean
    expect(response.body).to include("NO HACKR NAMED &#39;nobody&#39;")
  end
end
