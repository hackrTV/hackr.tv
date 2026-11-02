require "rails_helper"

# /root/grid_economy and /root/grid_transactions — the CRED economy
# readout and the transaction ledger as console screens
# (console-ui-for-all-admin Phase 4, 2026-11-01).
RSpec.describe "Admin grid economy and transactions", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:miner) { create(:grid_hackr, hackr_alias: "Miner", registration_ip: "10.9.8.7") }
  let!(:burn) { create(:grid_cache, :burn) }
  let!(:miner_cache) { create(:grid_cache, grid_hackr: miner, address: "CACHE-AAAA-0001", nickname: "stash") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def tx!(**attrs)
    GridTransaction.create!({from_cache: miner_cache, to_cache: burn, amount: 250, tx_type: "burn", tx_hash: SecureRandom.hex(32)}.merge(attrs))
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_economy"
    expect(response).not_to have_http_status(:ok)

    get "/root/grid_transactions"
    expect(response).not_to have_http_status(:ok)
  end

  it "renders the economy: supply tiles, abuse flags, caches, rigs, newest transactions, destinations and the prompt" do
    create(:grid_mining_rig, grid_hackr: miner, active: true)
    create(:grid_mining_rig, grid_hackr: create(:grid_hackr, registration_ip: "10.9.8.7"), active: true)
    tx!(from_cache: create(:grid_cache, :genesis), to_cache: miner_cache, amount: 1_234_817, tx_type: "genesis")
    tx!(memo: "scrap fee")
    log_in!(admin)

    get "/root/grid_economy"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("// SUPPLY //", "TOTAL SUPPLY", "1,000,000,000", "MINING POOL", "OF 700,000,000", "BURNED", "REDEEMED")
    expect(body).to include("// ABUSE FLAGS · 1 //", "10.9.8.7")
    expect(body).to include("// CACHES · 3 //", "CACHE-AAAA-0001", "Miner", "stash", "1,234,567", "[SYSTEM]", "BURN", "GENESIS")
    expect(body).to include("// MINING RIGS · 2 ACTIVE //")
    expect(body).to include("// TRANSACTIONS · NEWEST 100 //", "BURN", "250", "scrap fee", "CACHE-BURN-0000")
    expect(body).to include("/root/grid_transactions", "[TRANSACTIONS]", "[IMPOUND]")
    expect(body).not_to include("[ECONOMY]")
  end

  it "says so when nothing has moved yet" do
    GridCache.delete_all
    log_in!(admin)

    get "/root/grid_economy"

    expect(response.body).to be_console_clean
    expect(response.body).to include("NO CACHES ON RECORD", "NO ACTIVE MINING RIGS", "NO TRANSACTIONS YET")
    expect(response.body).not_to include("// ABUSE FLAGS")
  end

  it "lists the transactions with the filter rows, names over addresses, destinations and the prompt" do
    tx!(memo: "scrap fee")
    log_in!(admin)

    get "/root/grid_transactions"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("1 transaction", 'id="hackr_alias"', 'id="date_from"', 'id="date_to"', 'id="memo"', "[FILTER]", "[x] CLEAR")
    expect(body).to include("/root/grid_transactions?tx_type=mining_reward", "PURCHASE_RECYCLE")
    expect(body).to include("Miner", "CACHE-AAAA-0001", "[BURN]", "scrap fee")
    expect(body).to include("[ECONOMY]", "type a tag")
    expect(body).not_to include("[TRANSACTIONS]", "rc-pager")
  end

  it "filters by every field, keeps them in the TYPE links, and ignores an unknown type" do
    other = create(:grid_cache, grid_hackr: create(:grid_hackr, hackr_alias: "Other"))
    tx!(memo: "scrap fee", created_at: Time.zone.parse("2126-03-04 10:00"))
    tx!(from_cache: other, memo: "other fee", created_at: Time.zone.parse("2126-03-04 11:00"))
    tx!(memo: "scrap fee", tx_type: "transfer", to_cache: other, created_at: Time.zone.parse("2126-03-04 12:00"))
    log_in!(admin)

    get "/root/grid_transactions", params: {tx_type: "burn", hackr_alias: "miner", date_from: "2126-03-04", date_to: "2126-03-04", memo: "scrap"}

    body = response.body
    expect(body).to include("1 transaction", "filtered", 'value="miner"', 'value="2126-03-04"', 'value="scrap"')
    expect(body[/<input type="hidden" name="tx_type"[^>]*>/]).to include('value="burn"')
    expect(body).not_to include("other fee")
    expect(body).to include("/root/grid_transactions?date_from=2126-03-04&amp;date_to=2126-03-04&amp;hackr_alias=miner&amp;memo=scrap&amp;tx_type=transfer")
    expect(body[/<a[^>]*rc-btn--on[^>]*>BURN</]).to be_present

    get "/root/grid_transactions", params: {tx_type: "bogus"}
    expect(response.body).to include("3 transactions")
    expect(response.body).not_to include('name="tx_type"')
  end

  it "says when the hackr filter names nobody" do
    log_in!(admin)

    get "/root/grid_transactions", params: {hackr_alias: "ghost"}

    expect(response.body).to be_console_clean
    expect(response.body).to include("NO HACKR NAMED &#39;ghost&#39;")
  end

  it "pages 100 at a time and keeps the filters on the pager links" do
    101.times { |i| tx!(memo: "fee", created_at: Time.zone.parse("2126-01-01 00:00") + i.minutes) }
    log_in!(admin)

    get "/root/grid_transactions", params: {memo: "fee"}
    expect(response.body).to include("101 transactions", "rc-pager", "1–100 of 101", "/root/grid_transactions?memo=fee&amp;offset=100")

    get "/root/grid_transactions", params: {memo: "fee", offset: 100}
    expect(response.body).to include("101–101 of 101", "/root/grid_transactions?memo=fee&amp;offset=0")
  end
end
