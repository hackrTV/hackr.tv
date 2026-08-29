require "rails_helper"

# Server-rendered home page (Hotwire migration Phase 3).
RSpec.describe "Home page", type: :request do
  describe "GET /" do
    it "renders the terminal shell when nothing is scheduled or live" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("terminal-container")
      expect(response.body).to include('data-controller="terminal"')
      expect(response.body).not_to include("live-embed")
    end

    it "renders the live embed with the interim uplink panel when live" do
      artist = create(:artist)
      create(:hackr_stream, artist: artist, title: "FRACTURE SESSIONS",
        is_live: true, live_url: "https://www.youtube.com/watch?v=abc123xyz00")

      get "/"

      expect(response.body).to include("live-embed")
      expect(response.body).to include("FRACTURE SESSIONS")
      expect(response.body).to include("https://www.youtube.com/embed/abc123xyz00")
      expect(response.body).to include("OPEN UPLINK")
      expect(response.body).to include("[=] THEATER")
      expect(response.body).not_to include("terminal-container")
    end

    it "renders the scheduled banner and starting-soon hero" do
      artist = create(:artist)
      create(:hackr_stream, artist: artist, title: "COMING TRANSMISSION",
        scheduled_at: 30.minutes.ago) # within the 1-hour starting_soon window

      get "/"

      expect(response.body).to include("STREAM STARTING SOON")
      expect(response.body).to include("COMING TRANSMISSION")
    end

    it "renders the countdown banner for a future stream" do
      artist = create(:artist)
      create(:hackr_stream, artist: artist, title: "FUTURE SIGNAL", scheduled_at: 3.days.from_now)

      get "/"

      expect(response.body).to include("NEXT STREAM:")
      expect(response.body).to include("FUTURE SIGNAL")
      expect(response.body).to include('data-controller="countdown"')
      expect(response.body).to include("terminal-container") # idle content below the banner
    end
  end
end
