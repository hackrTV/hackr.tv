require "rails_helper"

# Server-rendered home page (Hotwire migration Phase 3); the idle state is
# the console (2026-10-28): banner + status block + one-line rows + prompt.
RSpec.describe "Home page", type: :request do
  describe "GET /" do
    it "renders the console when nothing is scheduled or live" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="console"')
      expect(response.body).to include('data-controller="terminal"')
      expect(response.body).to include('data-boot="pending"')
      expect(response.body).to include('id="greetings"') # the banner, drawn by the console
      expect(response.body).not_to include("chrome-ascii") # not by the chrome
      expect(response.body).to include("HACKR.TV BROADCAST SYSTEM")
      expect(response.body).to include("● ONLINE")
      expect(response.body).to include("ANONYMOUS")
      expect(response.body).to include("UNSCHEDULED")
      expect(response.body).to include("NO RECORD")
      expect(response.body).to include("// FEATURED ARTISTS //")
      expect(response.body).to include('data-command="0"')
      expect(response.body).to include("// PLATFORM SERVICES //")
      expect(response.body).to include('data-command="fm"')
      expect(response.body).to include('data-command="schedule"')
      expect(response.body).not_to include('data-command="uplink"') # logged-in only, like the nav
      expect(response.body).to include("// TRANSMISSION READY. SELECT YOUR DESTINATION. //")
      expect(response.body).to include('class="console-input"')
      expect(response.body).not_to include("live-embed")
    end

    it "fills the status block from the last and next broadcasts" do
      artist = create(:artist, name: "The.CyberPul.se")
      create(:hackr_stream, artist: artist, title: "NODE SESSIONS 07",
        started_at: Time.zone.local(2026, 10, 21, 20, 0), ended_at: Time.zone.local(2026, 10, 21, 22, 0))
      next_at = 3.days.from_now.change(hour: 20, min: 0)
      create(:hackr_stream, artist: artist, title: "NODE SESSIONS 08", started_at: nil, scheduled_at: next_at)

      get "/"

      expect(response.body).to include("LAST TX")
      expect(response.body).to include("2126-10-21 20:00") # century-shifted, compact
      expect(response.body).to include("NODE SESSIONS 07")
      expect(response.body).to include("NEXT TX")
      expect(response.body).to include((next_at + 100.years).strftime("%Y-%m-%d %H:%M"))
      expect(response.body).to include("NODE SESSIONS 08")
      expect(response.body).not_to include("UNSCHEDULED")
      expect(response.body).not_to include("NO RECORD")
    end

    it "renders the live embed with the docked uplink chat when live (Phase 5)" do
      artist = create(:artist)
      create(:hackr_stream, artist: artist, title: "FRACTURE SESSIONS",
        is_live: true, live_url: "https://www.youtube.com/watch?v=abc123xyz00")
      live_channel = create(:chat_channel, :livestream_only, slug: "live", name: "#live")
      create(:chat_message, chat_channel: live_channel, grid_hackr: create(:grid_hackr), content: "Docked chat packet")

      get "/"

      expect(response.body).to include("live-embed")
      expect(response.body).to include("FRACTURE SESSIONS")
      expect(response.body).to include("https://www.youtube.com/embed/abc123xyz00")
      expect(response.body).to include("[=] THEATER")
      expect(response.body).to include('class="theater-exit"') # floating exit shown in theater mode
      expect(response.body).to include('data-controller="theater stream-watch uplink-dock"')
      expect(response.body).to include("live-side-panel--uplink")
      expect(response.body).to include("Docked chat packet")
      expect(response.body).to include("to transmit packets") # anonymous login prompt
      expect(response.body).not_to include("OPEN UPLINK") # interim link panel replaced
      expect(response.body).to include("chrome-ascii") # the chrome's centered banner stays for the embed
      expect(response.body).not_to include('class="console"')
    end

    it "falls back to the link panel when no livestream channel exists" do
      artist = create(:artist)
      create(:hackr_stream, artist: artist, title: "FRACTURE SESSIONS",
        is_live: true, live_url: "https://www.youtube.com/watch?v=abc123xyz00")

      get "/"

      expect(response.body).to include("OPEN UPLINK")
      expect(response.body).not_to include("live-side-panel--uplink")
    end

    it "renders the scheduled banner and starting-soon hero" do
      artist = create(:artist)
      create(:hackr_stream, artist: artist, title: "COMING TRANSMISSION",
        scheduled_at: 30.minutes.ago) # within the 1-hour starting_soon window

      get "/"

      expect(response.body).to include("STREAM STARTING SOON")
      expect(response.body).to include("COMING TRANSMISSION")
      expect(response.body).to include("chrome-ascii")
      expect(response.body).not_to include('class="console"')
    end

    it "renders the countdown banner for a future stream" do
      artist = create(:artist)
      create(:hackr_stream, artist: artist, title: "FUTURE SIGNAL", scheduled_at: 3.days.from_now)

      get "/"

      expect(response.body).to include("NEXT STREAM:")
      expect(response.body).to include("FUTURE SIGNAL")
      expect(response.body).to include('data-controller="countdown"')
      expect(response.body).to include('class="console"') # idle content below the banner
    end
  end
end
