require "rails_helper"

# Phase 4: Hotwire hackr.fm landing + releases catalog (replaces
# FmLandingPage.tsx and FmReleasesPage.tsx).
RSpec.describe "FM pages", type: :request do
  let(:artist) { create(:artist, name: "Test Artist") }

  describe "GET /fm" do
    it "renders the lore and latest hackr.fm releases without the SPA root" do
      create(:release, :with_cover, artist: artist, name: "Neon Transmission", label: "hackr.fm")
      create(:release, :with_cover, artist: artist, name: "Grid Runner", label: "hackr.fm")

      get "/fm"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("hackr.fm opened as a frequency")
      expect(response.body).to include("Neon Transmission")
      expect(response.body).to include("Grid Runner")
    end

    it "excludes releases on other labels from the latest grid" do
      create(:release, :with_cover, artist: artist, name: "On Label", label: "hackr.fm")
      create(:release, :with_cover, artist: artist, name: "Off Label", label: "Other Records")

      get "/fm"

      expect(response.body).to include("On Label")
      expect(response.body).not_to include("Off Label")
    end

    it "renders coming-soon cards, hiding those beyond the first four" do
      5.times do |i|
        create(:release, :with_cover, artist: artist, name: "Incoming #{i + 1}",
          coming_soon: true, release_date: Date.current + i.days)
      end

      get "/fm"

      (1..5).each { |i| expect(response.body).to include("Incoming #{i}") }
      expect(response.body.scan("fm-soon-card-link--locked").size).to eq(1)
      expect(response.body).to include('fm-soon-card-link--locked" hidden="hidden"')
    end
  end

  describe "GET /fm/releases" do
    it "renders the hackr.fm release catalog" do
      create(:release, :with_cover, artist: artist, name: "Catalog One", label: "hackr.fm",
        catalog_number: "HFM-001")
      create(:release, artist: artist, name: "Catalog Two", label: "hackr.fm")

      get "/fm/releases"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("Catalog One")
      expect(response.body).to include("HFM-001")
      expect(response.body).to include("Catalog Two")
    end
  end
end
