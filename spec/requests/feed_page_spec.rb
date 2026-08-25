require "rails_helper"

# Server-rendered World Feed (Hotwire migration Phase 3).
RSpec.describe "Feed page", type: :request do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  def show_feed!
    WorldEventSetting.current.update!(visible: true)
  end

  describe "GET /feed" do
    it "redirects to root when the feed is hidden" do
      WorldEventSetting.current.update!(visible: false)

      get "/feed"

      expect(response).to redirect_to("/")
    end

    it "lets admins preview a hidden feed" do
      WorldEventSetting.current.update!(visible: false)
      admin = create(:grid_hackr, :admin, password: "hackthegrid")
      post "/grid/login", params: {hackr_alias: admin.hackr_alias, password: "hackthegrid"}

      get "/feed"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("HACKR.TV // WORLD FEED")
    end

    it "renders the last events with type colors and messages" do
      show_feed!
      WorldEvent.create!(event_type: "clearance_up", hackr_alias: "GhostWire", data: {"new_clearance" => 5})
      WorldEvent.create!(event_type: "achievement_unlocked", hackr_alias: "NullSec", data: {"achievement_name" => "First Blood"})

      get "/feed"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("GhostWire reached CLEARANCE 5")
      expect(response.body).to include("NullSec unlocked First Blood")
      expect(response.body).to include("#fbbf24") # clearance_up color
      expect(response.body).to include("turbo-cable-stream-source")
    end

    it "renders the empty state" do
      show_feed!

      get "/feed"

      expect(response.body).to include("Awaiting signal...")
    end

    it "caps the initial render at 50 events" do
      show_feed!
      55.times { |i| WorldEvent.create!(event_type: "manual", hackr_alias: "sys", data: {"message" => "event number #{i}"}) }

      get "/feed"

      expect(response.body).not_to include("event number 4\b")
      expect(response.body).to include("event number 54")
      expect(response.body.scan("feed-line\"").length).to eq(50)
    end
  end
end
