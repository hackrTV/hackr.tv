require "rails_helper"

# Phase 4: Hotwire radio page (replaces RadioPage.tsx).
RSpec.describe "Radio page", type: :request do
  describe "GET /fm/radio" do
    it "renders station cards with the three button variants" do
      playlist_station = create(:radio_station, name: "Playlist FM", stream_url: "")
      playlist = create(:playlist)
      create(:radio_station_playlist, radio_station: playlist_station, playlist: playlist)
      create(:radio_station, name: "Stream FM", stream_url: "http://example.com/stream")
      create(:radio_station, name: "Future FM", stream_url: "")

      get "/fm/radio"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("FRACTURE NETWORK RADIO STATIONS")
      expect(response.body).to include("Playlist FM")
      expect(response.body).to include("▶ PLAY STATION")
      expect(response.body).to include('data-controller="radio-station"')
      expect(response.body).to include("► TUNE IN")
      expect(response.body).to include("[COMING SOON]")
      expect(response.body).to include('data-controller="radio-stream"')
    end

    it "replaces the 2125 placeholder with the future year in descriptions" do
      create(:radio_station, description: "Broadcasting since 2125 from the grid")

      get "/fm/radio"

      expect(response.body).to include("Broadcasting since #{Date.current.year + 100} from the grid")
      expect(response.body).not_to include("since 2125")
    end

    it "links codex references in station descriptions" do
      create(:radio_station, description: "A beacon of the [[Fracture Network]]")

      get "/fm/radio"

      expect(response.body).to include('class="codex-link"')
      expect(response.body).to include("Fracture Network")
    end

    it "shows the WATCH LIVE card for thecyberpulse while streaming" do
      create(:radio_station, name: "TCP Broadcast", slug: "thecyberpulse", stream_url: "")
      artist = create(:artist)
      create(:hackr_stream, artist: artist, title: "LIVE FROM THE GRID", is_live: true,
        live_url: "https://www.youtube.com/embed/test123")

      get "/fm/radio"

      expect(response.body).to include("● LIVE NOW")
      expect(response.body).to include("▶ WATCH LIVE")
      expect(response.body).to include("LIVE FROM THE GRID")
    end

    it "hides invisible stations" do
      create(:radio_station, name: "Hidden FM", hidden: true)

      get "/fm/radio"

      expect(response.body).not_to include("Hidden FM")
    end
  end
end
