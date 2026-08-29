require "rails_helper"

# Grid meta pages (Hotwire migration Phase 6e) — read-only browsers over
# the same data the JSON API serves; mutations stay terminal commands.
RSpec.describe "Grid meta pages", type: :request do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone, name: "Relay Nexus") }
  let!(:hackr) do
    create(:grid_hackr, password: "hackthegrid", current_room: room,
      stats: {"tutorial_completed" => true})
  end

  def log_in!(as = hackr)
    post "/grid/login", params: {hackr_alias: as.hackr_alias, password: "hackthegrid"}
  end

  before do
    create(:feature_grant, grid_hackr: hackr, feature: FeatureGrant::PULSE_GRID)
  end

  it "requires login on every meta page" do
    %w[/achievements /missions /schematics /loadout /deck /transit].each do |path|
      get path
      expect(response).to have_http_status(:redirect), "expected #{path} to redirect anonymous"
    end
  end

  it "renders achievements with summary and category tabs" do
    log_in!
    get "/achievements"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ACHIEVEMENTS")
    expect(response.body).to include("Earned:")
    expect(response.body).to include('data-controller="meta-filter"')
  end

  it "renders missions inside the live-refresh frame with the three tabs" do
    log_in!
    get "/missions"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="grid-missions"')
    expect(response.body).to include('data-controller="mission-refresh"')
    expect(response.body).to include("ACTIVE (0)")
    expect(response.body).to include("AVAILABLE (0)")
    expect(response.body).to include("COMPLETED (0)")
    expect(response.body).to include("No active missions")
  end

  it "lists an available mission from a giver in the current room (all_met? regression)" do
    log_in!
    giver = create(:grid_mob, :quest_giver, grid_room: room, name: "Broker Nyx")
    mission = create(:grid_mission, giver_mob: giver, name: "Cable Run")

    get "/missions"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AVAILABLE (1)")
    expect(response.body).to include("Cable Run")
    expect(response.body).to include("accept #{mission.slug}")
  end

  it "renders schematics with status tabs" do
    log_in!
    get "/schematics"

    expect(response.body).to include("FABRICATION SCHEMATICS")
    expect(response.body).to include("READY (0)")
  end

  it "renders the 13-slot loadout with vitals" do
    log_in!
    get "/loadout"

    expect(response.body).to include("LOADOUT")
    expect(response.body).to include("0/13 slots equipped")
    expect(response.body).to include("HEALTH")
    expect(response.body).to include("-- empty --")
  end

  it "renders the deck page empty state" do
    log_in!
    get "/deck"

    expect(response.body).to include("DECK STATUS")
    expect(response.body).to include("No DECK equipped.")
  end

  it "renders transit with the three browser tabs" do
    log_in!
    get "/transit"

    expect(response.body).to include("TRANSIT SYSTEM")
    expect(response.body).to include("LOCAL TRANSIT")
    expect(response.body).to include("SLIPSTREAM")
    expect(response.body).to include("REGION NETWORK")
    expect(response.body).to include("Corridor Heat")
  end

  it "gates behind pulse_grid" do
    other = create(:grid_hackr, password: "hackthegrid", current_room: room,
      stats: {"tutorial_completed" => true})
    post "/grid/login", params: {hackr_alias: other.hackr_alias, password: "hackthegrid"}

    get "/achievements"

    expect(response.body).to include("will open soon")
  end
end
