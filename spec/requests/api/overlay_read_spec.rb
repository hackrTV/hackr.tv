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

  describe "GET /api/overlay/tickers" do
    let!(:active_ticker) { create(:overlay_ticker, name: "Top Ticker", slug: "top-ticker") }
    let!(:dynamic_ticker) { create(:overlay_ticker, :dynamic, name: "Bottom Ticker", slug: "bottom-ticker") }
    let!(:inactive_ticker) { create(:overlay_ticker, :inactive, name: "Hidden Ticker", slug: "hidden-ticker") }

    it "returns active tickers by default" do
      get "/api/overlay/tickers"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      slugs = body["tickers"].map { |t| t["slug"] }
      expect(slugs).to include("top-ticker", "bottom-ticker")
      expect(slugs).not_to include("hidden-ticker")
    end

    it "returns all tickers when active=all" do
      get "/api/overlay/tickers", params: {active: "all"}

      body = JSON.parse(response.body)
      slugs = body["tickers"].map { |t| t["slug"] }
      expect(slugs).to include("top-ticker", "bottom-ticker", "hidden-ticker")
    end

    it "filters by slug" do
      get "/api/overlay/tickers", params: {slug: "top-ticker"}

      body = JSON.parse(response.body)
      expect(body["tickers"].size).to eq(1)
      expect(body["tickers"][0]["slug"]).to eq("top-ticker")
    end

    it "includes all expected fields" do
      get "/api/overlay/tickers"

      body = JSON.parse(response.body)
      ticker = body["tickers"].find { |t| t["slug"] == "bottom-ticker" }
      expect(ticker["name"]).to eq("Bottom Ticker")
      expect(ticker["content_type"]).to eq("dynamic")
      expect(ticker["feed_source"]).to eq("api")
      expect(ticker["direction"]).to eq("left")
      expect(ticker["speed"]).to eq(50)
      expect(ticker["active"]).to be true
    end
  end

  describe "GET /api/overlay/lower-thirds" do
    let!(:active_lt) { create(:overlay_lower_third, name: "Guest", slug: "guest", primary_text: "DJ Phantom") }
    let!(:inactive_lt) { create(:overlay_lower_third, :inactive, name: "Hidden", slug: "hidden") }

    it "returns active lower thirds by default" do
      get "/api/overlay/lower-thirds"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      slugs = body["lower_thirds"].map { |lt| lt["slug"] }
      expect(slugs).to include("guest")
      expect(slugs).not_to include("hidden")
    end

    it "returns all when active=all" do
      get "/api/overlay/lower-thirds", params: {active: "all"}

      body = JSON.parse(response.body)
      expect(body["lower_thirds"].size).to eq(2)
    end

    it "filters by slug" do
      get "/api/overlay/lower-thirds", params: {slug: "guest"}

      body = JSON.parse(response.body)
      expect(body["lower_thirds"].size).to eq(1)
      expect(body["lower_thirds"][0]["primary_text"]).to eq("DJ Phantom")
    end

    it "includes all expected fields" do
      get "/api/overlay/lower-thirds"

      body = JSON.parse(response.body)
      lt = body["lower_thirds"][0]
      expect(lt).to include("slug", "name", "primary_text", "secondary_text", "logo_url", "active")
    end
  end

  describe "GET /api/overlay/scenes" do
    let!(:scene) { create(:overlay_scene, name: "Main", slug: "main") }
    let!(:inactive_scene) { create(:overlay_scene, :inactive, name: "Draft", slug: "draft") }

    before do
      create_list(:overlay_scene_element, 3, overlay_scene: scene)
    end

    it "returns active scenes by default" do
      get "/api/overlay/scenes"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      slugs = body["scenes"].map { |s| s["slug"] }
      expect(slugs).to include("main")
      expect(slugs).not_to include("draft")
    end

    it "returns all when active=all" do
      get "/api/overlay/scenes", params: {active: "all"}

      body = JSON.parse(response.body)
      expect(body["scenes"].size).to eq(2)
    end

    it "includes element count and groups" do
      group = create(:overlay_scene_group, slug: "cyberpulse")
      create(:overlay_scene_group_scene, overlay_scene_group: group, overlay_scene: scene)

      get "/api/overlay/scenes"

      body = JSON.parse(response.body)
      s = body["scenes"].find { |s| s["slug"] == "main" }
      expect(s["element_count"]).to eq(3)
      expect(s["groups"]).to include("cyberpulse")
    end

    it "filters by group slug" do
      group = create(:overlay_scene_group, slug: "test-group")
      create(:overlay_scene_group_scene, overlay_scene_group: group, overlay_scene: scene)
      create(:overlay_scene, name: "Other", slug: "other")

      get "/api/overlay/scenes", params: {group: "test-group"}

      body = JSON.parse(response.body)
      slugs = body["scenes"].map { |s| s["slug"] }
      expect(slugs).to eq(["main"])
    end
  end

  describe "GET /api/overlay/scenes/:slug" do
    let!(:scene) { create(:overlay_scene, slug: "cyberpulse-main", settings: {"bg" => "#000"}) }
    let!(:element) { create(:overlay_element, name: "Now Playing Widget", slug: "now-playing", element_type: "now_playing", settings: {"theme" => "dark"}) }
    let!(:scene_element) do
      create(:overlay_scene_element,
        overlay_scene: scene,
        overlay_element: element,
        x: 50, y: 900, width: 400, height: 150, z_index: 10,
        overrides: {"color" => "#fff"})
    end

    it "returns full scene composition" do
      get "/api/overlay/scenes/cyberpulse-main"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      s = body["scene"]
      expect(s["slug"]).to eq("cyberpulse-main")
      expect(s["settings"]).to eq({"bg" => "#000"})
      expect(s["elements"].size).to eq(1)

      el = s["elements"][0]
      expect(el["element_name"]).to eq("Now Playing Widget")
      expect(el["element_slug"]).to eq("now-playing")
      expect(el["element_type"]).to eq("now_playing")
      expect(el["x"]).to eq(50)
      expect(el["y"]).to eq(900)
      expect(el["width"]).to eq(400)
      expect(el["height"]).to eq(150)
      expect(el["z_index"]).to eq(10)
      expect(el["settings"]).to eq({"theme" => "dark"})
      expect(el["overrides"]).to eq({"color" => "#fff"})
    end

    it "returns 404 for unknown slug" do
      get "/api/overlay/scenes/nonexistent"

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Scene not found")
    end
  end

  describe "GET /api/overlay/scene-groups" do
    it "returns groups with scene slugs and positions" do
      group = create(:overlay_scene_group, name: "CyberPulse", slug: "cyberpulse")
      scene_a = create(:overlay_scene, slug: "cyberpulse-main")
      scene_b = create(:overlay_scene, slug: "cyberpulse-break")
      create(:overlay_scene_group_scene, overlay_scene_group: group, overlay_scene: scene_a, position: 1)
      create(:overlay_scene_group_scene, overlay_scene_group: group, overlay_scene: scene_b, position: 2)

      get "/api/overlay/scene-groups"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      g = body["scene_groups"][0]
      expect(g["slug"]).to eq("cyberpulse")
      expect(g["name"]).to eq("CyberPulse")
      expect(g["scenes"]).to eq([
        {"slug" => "cyberpulse-main", "position" => 1},
        {"slug" => "cyberpulse-break", "position" => 2}
      ])
    end
  end

  describe "GET /api/overlay/elements" do
    let!(:active_element) { create(:overlay_element, slug: "now-playing", settings: {"theme" => "dark"}) }
    let!(:inactive_element) { create(:overlay_element, :inactive, slug: "hidden-element") }

    it "returns active elements by default" do
      get "/api/overlay/elements"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      slugs = body["elements"].map { |e| e["slug"] }
      expect(slugs).to include("now-playing")
      expect(slugs).not_to include("hidden-element")
    end

    it "returns all when active=all" do
      get "/api/overlay/elements", params: {active: "all"}

      body = JSON.parse(response.body)
      expect(body["elements"].size).to eq(2)
    end

    it "includes all expected fields" do
      get "/api/overlay/elements"

      body = JSON.parse(response.body)
      el = body["elements"][0]
      expect(el).to include("slug", "name", "element_type", "active", "settings")
      expect(el["settings"]).to eq({"theme" => "dark"})
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

  describe "CORS headers" do
    it "includes Access-Control-Allow-Origin on overlay read endpoints" do
      get "/api/overlay/now-playing", headers: {"Origin" => "http://localhost:3001"}

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    end
  end
end
