require "rails_helper"

RSpec.describe TracksController, type: :request do
  # TracksController now only handles legacy redirects
  # Track viewing is Hotwire since Phase 4 (ArtistCatalogController)

  describe "Legacy redirects" do
    describe "GET /trackz" do
      it "redirects to thecyberpulse releases path" do
        get "/trackz"
        expect(response).to redirect_to("/thecyberpulse/releases")
        expect(response).to have_http_status(301)
      end
    end

    describe "GET /trackz/:id" do
      it "redirects to thecyberpulse track path" do
        get "/trackz/test-track"
        expect(response).to redirect_to("/thecyberpulse/trackz/test-track")
        expect(response).to have_http_status(301)
      end
    end
  end

  # Track detail pages are Hotwire since Phase 4 (see artist_catalog_spec
  # for full coverage) — these examples pin the route → stack ownership.
  describe "Hotwire track routes" do
    describe "GET /thecyberpulse/trackz/:id" do
      it "renders the Hotwire track page, not the SPA" do
        artist = create(:artist, slug: "thecyberpulse")
        release = create(:release, artist: artist)
        create(:track, artist: artist, release: release, slug: "test-track", title: "Test Track")

        get "/thecyberpulse/trackz/test-track"
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('<div id="root">')
        expect(response.body).to include("Test Track")
      end
    end

    describe "GET /xeraen/trackz/:id" do
      it "renders the Hotwire track page, not the SPA" do
        artist = create(:artist, slug: "xeraen")
        release = create(:release, artist: artist)
        create(:track, artist: artist, release: release, slug: "xeraen-track", title: "Xeraen Track")

        get "/xeraen/trackz/xeraen-track"
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('<div id="root">')
        expect(response.body).to include("Xeraen Track")
      end
    end
  end
end
