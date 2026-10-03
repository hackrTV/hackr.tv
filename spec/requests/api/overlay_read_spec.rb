require "rails_helper"

RSpec.describe "Overlay Read API", type: :request do
  describe "GET /api/overlay/now-playing" do
    it "returns current now-playing state when nothing playing" do
      get "/api/overlay/now-playing"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["playing"]).to be false
      expect(body["title"]).to eq("Nothing Playing")
      expect(body["artist"]).to eq("")
      expect(body["album"]).to eq("")
      expect(body["album_cover"]).to be_nil
      expect(body["track_id"]).to be_nil
      expect(body["paused"]).to be false
      expect(body["is_live"]).to be false
      expect(body["started_at"]).to be_nil
    end

    it "returns track info when a track is playing" do
      artist = create(:artist)
      release = create(:release, artist: artist)
      track = create(:track, artist: artist, release: release)
      OverlayNowPlaying.set_track!(track)

      get "/api/overlay/now-playing"

      body = JSON.parse(response.body)
      expect(body["playing"]).to be true
      expect(body["title"]).to eq(track.title)
      expect(body["artist"]).to eq(artist.name)
      expect(body["album"]).to eq(release.name)
      expect(body["track_id"]).to eq(track.id)
      expect(body["paused"]).to be false
      expect(body["started_at"]).to be_present
    end

    it "returns custom title when set" do
      OverlayNowPlaying.set_custom!(title: "Custom Song", artist: "Custom Artist")

      get "/api/overlay/now-playing"

      body = JSON.parse(response.body)
      expect(body["playing"]).to be true
      expect(body["title"]).to eq("Custom Song")
      expect(body["artist"]).to eq("Custom Artist")
    end
  end

  describe "GET /api/overlay/alerts/pending" do
    it "returns pending undisplayed alerts" do
      pending_alert = create(:overlay_alert, :pending, title: "New Sub!", alert_type: "subscriber")
      create(:overlay_alert, :displayed) # should be excluded
      create(:overlay_alert, :expired) # should be excluded

      get "/api/overlay/alerts/pending"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["alerts"].size).to eq(1)
      alert = body["alerts"][0]
      expect(alert["id"]).to eq(pending_alert.id)
      expect(alert["alert_type"]).to eq("subscriber")
      expect(alert["title"]).to eq("New Sub!")
      expect(alert["expires_at"]).to be_present
      expect(alert["created_at"]).to be_present
    end

    it "includes alerts without expiry" do
      create(:overlay_alert, title: "No Expiry")

      get "/api/overlay/alerts/pending"

      body = JSON.parse(response.body)
      expect(body["alerts"].size).to eq(1)
      expect(body["alerts"][0]["expires_at"]).to be_nil
    end
  end

  describe "retired endpoints" do
    # The hackr.tv-native overlay system (scenes, elements, tickers, lower
    # thirds, /overlays pages) was removed — the HUD app renders overlays and
    # reads only now-playing + alerts/pending.
    %w[
      /api/overlay/tickers
      /api/overlay/lower-thirds
      /api/overlay/scenes
      /api/overlay/scenes/main
      /api/overlay/scene-groups
      /api/overlay/elements
      /overlays/now-playing
      /overlays/scenes/main
      /overlays/ticker/top
    ].each do |path|
      it "404s #{path}" do
        get path
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "CORS headers" do
    it "includes Access-Control-Allow-Origin on overlay read endpoints" do
      get "/api/overlay/now-playing", headers: {"Origin" => "http://localhost:3001"}

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    end

    it "includes Access-Control-Allow-Origin on the world event feed" do
      get "/api/world_events", headers: {"Origin" => "http://localhost:5173"}

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    end

    it "does not open CORS on other API paths" do
      get "/api/settings", headers: {"Origin" => "http://localhost:5173"}

      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end
  end
end
