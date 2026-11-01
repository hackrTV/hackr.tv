require "rails_helper"

# /root/grid_transit_journeys — the newest journeys and one journey's
# readout as console screens (console-ui-for-all-admin Phase 3,
# 2026-10-31).
RSpec.describe "Admin grid transit journeys", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:rider) { create(:grid_hackr, hackr_alias: "Rider") }
  let!(:route) { create(:grid_slipstream_route, name: "Lake Run") }
  let!(:origin) { create(:grid_room, name: "Dock Gate") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def journey!(**attrs)
    GridTransitJourney.create!({grid_hackr: rider, journey_type: "slipstream", grid_slipstream_route: route, origin_room: origin,
                                state: "active", started_at: Time.zone.parse("2126-01-02 03:04"), meta: {}}.merge(attrs))
  end

  # .env sets ADMIN_DEV_TOOLS=true for local work; the gate is off here
  # unless an example turns it on.
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return(nil)
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_transit_journeys"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the journeys with the STATE and TYPE rows, destinations and the prompt" do
    journey = journey!
    journey!(grid_hackr: create(:grid_hackr), state: "completed", journey_type: "local_public", grid_slipstream_route: nil)
    log_in!(admin)

    get "/root/grid_transit_journeys"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 journeys", "[01]", "[02]", 'data-command="02"', "Rider", "##{journey.id}", "SLIPSTREAM", "Lake Run", "ACTIVE", "COMPLETED", "2126-01-02 03:04")
    expect(body).to include("/root/grid_transit_journeys/#{journey.id}", "/root/grid_transit_journeys?state=abandoned", "/root/grid_transit_journeys?journey_type=local_private")
    expect(body).not_to include("[ABANDON]", "DEV TOOLS ON")
    expect(body).to include("[SLIPSTREAM]", "[ROUTES]")
    expect(body).not_to include("[JOURNEYS]")
    expect(body).to include("type a journey number")
  end

  it "narrows by state and type, keeps the other in the links, and ignores unknown values" do
    journey!
    journey!(grid_hackr: create(:grid_hackr, hackr_alias: "Walker"), state: "completed")
    log_in!(admin)

    get "/root/grid_transit_journeys", params: {state: "completed", journey_type: "slipstream"}
    expect(response.body).to include("Walker", "COMPLETED · SLIPSTREAM", "/root/grid_transit_journeys?journey_type=slipstream&amp;state=active")
    expect(response.body).not_to include("Rider")
    expect(response.body).to include('class="rc-btn rc-btn--on" aria-current="page" href="/root/grid_transit_journeys?journey_type=slipstream&amp;state=completed"')

    get "/root/grid_transit_journeys", params: {state: "bogus"}
    expect(response.body).to include("Rider", "Walker")
  end

  it "renders a journey's readout" do
    journey = journey!(meta: {"fork" => "A"}, heat_accumulated: 7)
    log_in!(admin)

    get "/root/grid_transit_journeys/#{journey.id}"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("JOURNEY ##{journey.id}", "// JOURNEY //", "Rider", "Dock Gate", "// ROUTE //", "Lake Run", "/root/grid_slipstream_routes/#{route.slug}/edit")
    expect(body).to include("HEAT", "7", "// META //", "&quot;fork&quot;: &quot;A&quot;")
    expect(body).not_to include("FORCE ABANDON")
  end

  it "refuses a force-abandon while dev tools are off" do
    journey = journey!
    log_in!(admin)

    post "/root/grid_transit_journeys/#{journey.id}/force_abandon"

    expect(response).to redirect_to("/root")
    expect(journey.reload.state).to eq("active")
  end

  it "force-abandons an active journey from the ledger and the readout while dev tools are on" do
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return("true")
    journey = journey!
    log_in!(admin)

    get "/root/grid_transit_journeys"
    expect(response.body).to include("DEV TOOLS ON", "[ABANDON]", "/root/grid_transit_journeys/#{journey.id}/force_abandon", "data-confirm=\"Force-abandon journey ##{journey.id}?\"")

    get "/root/grid_transit_journeys/#{journey.id}"
    expect(response.body).to include("// DEV TOOLS //", "[FORCE ABANDON]")

    post "/root/grid_transit_journeys/#{journey.id}/force_abandon"
    expect(response).to redirect_to("/root/grid_transit_journeys/#{journey.id}")
    follow_redirect!
    expect(response.body).to include("[OK]", "Journey ##{journey.id} force-abandoned.", "ABANDONED")
    expect(rider.reload.current_room).to eq(origin)
  end
end
