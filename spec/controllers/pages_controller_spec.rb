require "rails_helper"

RSpec.describe PagesController, type: :request do
  # The SPA shell now serves only THE PULSE GRID; everything else is
  # Hotwire. Per-page rendering is covered by the dedicated request
  # specs (wire/feed/home/vault/fm/radio/playlists/artist/uplink specs) —
  # this file just pins which stack owns which route family.

  describe "SPA routes" do
    it "has none left — no route serves pages#spa_root after Phase 6e" do
      spa_routes = Rails.application.routes.routes.select { |r|
        r.defaults[:controller] == "pages" && r.defaults[:action] == "spa_root"
      }
      expect(spa_routes).to be_empty
    end
  end

  describe "Hotwire routes (no SPA shell)" do
    describe "GET /" do
      it "renders the Hotwire home page (migrated Phase 3)" do
        get "/"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("terminal-container")
        expect(response.body).not_to include('<div id="root">')
      end
    end

    describe "GET /logs" do
      it "is served by the Hotwire logs page (migrated Phase 1)" do
        get "/logs"
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('<div id="root">')
        expect(response.body).to include("HACKR LOGS")
      end
    end

    describe "GET /vault" do
      it "is served by the Hotwire vault (migrated Phase 4)" do
        get "/vault"
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('<div id="root">')
        expect(response.body).to include("PULSE VAULT")
      end
    end

    describe "GET /uplink/popout" do
      it "is served by the Hotwire uplink popout (migrated Phase 5)" do
        get "/uplink/popout"
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('<div id="root">')
        expect(response.body).to include("UPLINK")
      end
    end

    describe "GET /grid" do
      it "is served by the Hotwire terminal (migrated Phase 6a) — login-gated" do
        get "/grid"
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/grid/login")
      end
    end
  end

  describe "legacy redirects" do
    it "GET /fm/pulse-vault redirects to /vault" do
      get "/fm/pulse-vault"
      expect(response).to redirect_to("/vault")
    end

    it "GET /pulse-vault redirects to /vault" do
      get "/pulse-vault"
      expect(response).to redirect_to("/vault")
    end
  end
end
