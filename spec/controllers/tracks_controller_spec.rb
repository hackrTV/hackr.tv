require "rails_helper"

RSpec.describe TracksController, type: :request do
  let(:artist) { create(:artist, :thecyberpulse) }
  let(:xeraen_artist) { create(:artist, :xeraen) }

  describe "GET /trackz" do
    let!(:track1) { create(:track, artist: artist, title: "Track 1", featured: true, release_date: Date.today) }
    let!(:track2) { create(:track, artist: artist, title: "Track 2", featured: false, release_date: Date.yesterday) }

    it "returns http success" do
      get "/trackz"
      expect(response).to have_http_status(:success)
    end

    it "displays tracks for The.CyberPul.se" do
      get "/trackz"
      expect(response.body).to include("Track 1")
      expect(response.body).to include("Track 2")
    end
  end

  describe "GET /xeraen/trackz" do
    let!(:track1) { create(:track, artist: xeraen_artist, title: "XERAEN Track 1") }

    it "returns http success" do
      get "/xeraen/trackz"
      expect(response).to have_http_status(:success)
    end

    it "displays tracks for XERAEN" do
      get "/xeraen/trackz"
      expect(response.body).to include("XERAEN Track 1")
    end
  end

  describe "GET /trackz/:id" do
    let!(:track) { create(:track, artist: artist, slug: "test-track", title: "Test Track") }

    it "returns http success" do
      get "/trackz/test-track"
      expect(response).to have_http_status(:success)
    end

    it "displays the track details" do
      get "/trackz/test-track"
      expect(response.body).to include("Test Track")
    end
  end

  describe "GET /xeraen/trackz/:id" do
    let!(:track) { create(:track, artist: xeraen_artist, slug: "xeraen-track", title: "XERAEN Track") }

    it "returns http success" do
      get "/xeraen/trackz/xeraen-track"
      expect(response).to have_http_status(:success)
    end

    it "displays the track details" do
      get "/xeraen/trackz/xeraen-track"
      expect(response.body).to include("XERAEN Track")
    end
  end
end
