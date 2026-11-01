require "rails_helper"

# /root/grid_impound_records — the impound ledger and its dev-tool force
# recover / forfeit as a console screen (console-ui-for-all-admin Phase
# 4, 2026-11-01).
RSpec.describe "Admin grid impound records", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:runner) { create(:grid_hackr, hackr_alias: "Runner") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def dev_tools!(on)
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return(on ? "true" : nil)
  end

  # .env sets ADMIN_DEV_TOOLS=true for local work; the gate is off here
  # unless an example turns it on.
  before do
    allow(ENV).to receive(:[]).and_call_original
    dev_tools!(false)
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_impound_records"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the records with the filter rows, destinations and the prompt, no force buttons without dev tools" do
    record = create(:grid_impound_record, grid_hackr: runner, bribe_cost: 750)
    create(:grid_item, :in_inventory, grid_hackr: runner, grid_impound_record: record)
    create(:grid_impound_record, :recovered)
    log_in!(admin)

    get "/root/grid_impound_records"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 records", "1 impounded", "##{record.id}", "Runner", "/root/grid_hackrs/#{runner.id}", "IMPOUNDED", "RECOVERED", "750")
    expect(body).to include('id="hackr_alias"', "/root/grid_impound_records?status=forfeited")
    expect(body).not_to include("[RECOVER]", "[FORFEIT]", "DEV TOOLS ON")
    expect(body).to include("[ECONOMY]")
    expect(body).not_to include("[IMPOUND]")
  end

  it "narrows by hackr and status, keeps the hackr in the STATUS links, and ignores an unknown status" do
    create(:grid_impound_record, grid_hackr: runner)
    create(:grid_impound_record, :forfeited, grid_hackr: runner)
    create(:grid_impound_record, grid_hackr: create(:grid_hackr, hackr_alias: "Walker"))
    log_in!(admin)

    get "/root/grid_impound_records", params: {hackr_alias: "runner", status: "impounded"}
    body = response.body
    expect(body).to include("1 record", "filtered", 'value="runner"', "/root/grid_impound_records?hackr_alias=runner&amp;status=forfeited")
    expect(body[/<input type="hidden" name="status"[^>]*>/]).to include('value="impounded"')
    expect(body).not_to include("Walker")

    get "/root/grid_impound_records", params: {status: "bogus"}
    expect(response.body).to include("3 records")
    expect(response.body).not_to include('name="status"')

    get "/root/grid_impound_records", params: {hackr_alias: "ghost"}
    expect(response.body).to include("NO HACKR NAMED &#39;ghost&#39;")
  end

  it "force-recovers and force-forfeits with dev tools on, each confirming first" do
    dev_tools!(true)
    keep = create(:grid_impound_record, grid_hackr: runner)
    item = create(:grid_item, :in_inventory, grid_hackr: runner, grid_impound_record: keep)
    lose = create(:grid_impound_record, grid_hackr: runner)
    lost = create(:grid_item, :in_inventory, grid_hackr: runner, grid_impound_record: lose)
    log_in!(admin)

    get "/root/grid_impound_records"
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("DEV TOOLS ON", "[RECOVER]", "[FORFEIT]")
    expect(body[%r{<form[^>]*action="/root/grid_impound_records/#{keep.id}/force_recover"[^>]*>}]).to include("data-confirm=\"Force-recover impound ##{keep.id}?")
    expect(body[%r{<form[^>]*action="/root/grid_impound_records/#{lose.id}/force_forfeit"[^>]*>}]).to include("data-confirm=\"Force-forfeit impound ##{lose.id}?")

    post "/root/grid_impound_records/#{keep.id}/force_recover"
    expect(response).to redirect_to("/root/grid_impound_records")
    follow_redirect!
    expect(response.body).to include("[OK]", "Force-recovered impound ##{keep.id}")
    expect(keep.reload.status).to eq("recovered")
    expect(item.reload.grid_impound_record_id).to be_nil

    post "/root/grid_impound_records/#{lose.id}/force_forfeit"
    follow_redirect!
    expect(response.body).to include("[OK]", "Force-forfeited impound ##{lose.id}")
    expect(lose.reload.status).to eq("forfeited")
    expect(GridItem.exists?(lost.id)).to be(false)
  end

  it "refuses the force actions without dev tools" do
    record = create(:grid_impound_record, grid_hackr: runner)
    log_in!(admin)

    post "/root/grid_impound_records/#{record.id}/force_recover"

    expect(response).to redirect_to("/root")
    expect(record.reload.status).to eq("impounded")
  end
end
