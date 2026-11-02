require "rails_helper"

# /root/grid_reputation_events and /root/grid_hackr_reputations — the rep
# log and every hackr's standings (+ the manual adjust) as console
# screens (console-ui-for-all-admin Phase 4, 2026-11-01).
RSpec.describe "Admin grid reputation screens", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:runner) { create(:grid_hackr, hackr_alias: "Runner") }
  let!(:fracture) { create(:grid_faction, name: "Fracture", slug: "fracture") }
  let!(:govcorp) { create(:grid_faction, name: "GovCorp", slug: "govcorp") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def event!(**attrs)
    GridReputationEvent.create!({grid_hackr: runner, subject: fracture, delta: 5, value_after: 5, reason: "talk:dockhand"}.merge(attrs))
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_reputation_events"
    expect(response).not_to have_http_status(:ok)

    get "/root/grid_hackr_reputations"
    expect(response).not_to have_http_status(:ok)
  end

  it "lists the rep log with the filter rows, destinations and the prompt" do
    event!(note: "first contact", created_at: Time.zone.parse("2126-02-03 04:05:06"))
    event!(subject: govcorp, delta: -3, value_after: -3, reason: "admin:manual")
    log_in!(admin)

    get "/root/grid_reputation_events"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 events", 'id="hackr_alias"', 'id="faction_slug"', 'id="reason"', "ANY FACTION")
    expect(body).to include("2126-02-03 04:05:06", "Runner", "Fracture", "+5", "-3", "talk:dockhand", "first contact", "GovCorp")
    expect(body).to include("[REPUTATIONS]", "[ECONOMY]")
    expect(body).not_to include("[REPLOG]")
  end

  it "filters the rep log by hackr, faction and reason prefix" do
    event!
    event!(subject: govcorp, reason: "buy:stim")
    event!(grid_hackr: create(:grid_hackr, hackr_alias: "Other"), reason: "talk:other")
    log_in!(admin)

    get "/root/grid_reputation_events", params: {hackr_alias: "runner", faction_slug: "fracture", reason: "talk:"}

    body = response.body
    expect(body).to include("1 event", "filtered", 'value="runner"', 'value="talk:"', %(<option selected="selected" value="fracture">))
    expect(body).not_to include("buy:stim", "talk:other")

    get "/root/grid_reputation_events", params: {hackr_alias: "ghost"}
    expect(response.body).to include("NO HACKR NAMED &#39;ghost&#39;")
  end

  it "lists the standings with the filter and the adjust form (leaf factions only)" do
    aggregate = create(:grid_faction, name: "Syndicate", slug: "syndicate")
    create(:grid_faction_rep_link, source_faction: fracture, target_faction: aggregate)
    GridHackrReputation.create!(grid_hackr: runner, subject: fracture, value: 12)
    GridHackrReputation.create!(grid_hackr: runner, subject: govcorp, value: -4)
    log_in!(admin)

    get "/root/grid_hackr_reputations"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 standings", "Runner", "Fracture", "+12", "-4")
    adjust = body[%r{<form[^>]*action="/root/grid_hackr_reputations/adjust".*?</form>}m]
    expect(adjust).to include('name="grid_hackr_id"', 'name="grid_faction_id"', 'name="delta"', 'name="reason"', 'value="admin:manual"', 'name="note"', "[APPLY]")
    expect(adjust).to include(">Fracture<", ">GovCorp<")
    expect(adjust).not_to include(">Syndicate<")
    expect(body).to include("[REPLOG]")
    expect(body).not_to include("[REPUTATIONS]")

    get "/root/grid_hackr_reputations", params: {hackr_alias: "runner", faction_slug: "govcorp"}
    expect(response.body).to include("1 standing", "-4")
    expect(response.body).not_to include("+12")
  end

  it "applies an adjustment and replies under the bar; refuses a zero delta" do
    log_in!(admin)

    post "/root/grid_hackr_reputations/adjust", params: {grid_hackr_id: runner.id, grid_faction_id: fracture.id, delta: "7", reason: "admin:test", note: "spec"}

    expect(response).to redirect_to("/root/grid_hackr_reputations")
    follow_redirect!
    expect(response.body).to be_console_clean
    expect(response.body).to include("[OK]", "Runner :: Fracture +7 &gt; 7")
    event = GridReputationEvent.last
    expect(event).to have_attributes(grid_hackr_id: runner.id, subject_id: fracture.id, delta: 7, reason: "admin:test", note: "spec")

    post "/root/grid_hackr_reputations/adjust", params: {grid_hackr_id: runner.id, grid_faction_id: fracture.id, delta: "0"}
    follow_redirect!
    expect(response.body).to include("[ERR]", "Delta must be non-zero.")
  end
end
