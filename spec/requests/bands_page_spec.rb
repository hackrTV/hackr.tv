require "rails_helper"

# Phase 4: Hotwire Fracture Network roster at /f/net (replaces BandsPage.tsx).
RSpec.describe "Bands page", type: :request do
  describe "GET /f/net" do
    it "renders the band roster with BandsHelper descriptions" do
      create(:artist, name: "Synthia", slug: "synthia", artist_type: "band")
      create(:artist, name: "Fresh Signal", slug: "fresh-signal", artist_type: "band")

      get "/f/net"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("FRACTURE NETWORK")
      expect(response.body).to include("SYNTHIA")
      expect(response.body).to include("FRESH SIGNAL")
      # Curated description for a known slug, fallback line for the rest.
      expect(response.body).to include("Unbound AI singing through time")
      expect(response.body).to include("Broadcasting truth through sound.")
    end

    it "only lists band-type artists" do
      create(:artist, name: "Roster Band", artist_type: "band")
      create(:artist, name: "Score Only", artist_type: "ost")

      get "/f/net"

      expect(response.body).to include("ROSTER BAND")
      expect(response.body).not_to include("SCORE ONLY")
    end
  end
end
