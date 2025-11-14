require "rails_helper"

RSpec.describe PagesController, type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "displays hackr.tv home content" do
      get "/"
      expect(response.body).to include("Welcome to hackr.tv")
    end
  end

  describe "GET /thecyberpulse" do
    it "returns http success" do
      get "/thecyberpulse"
      expect(response).to have_http_status(:success)
    end

    it "displays The.CyberPul.se content" do
      get "/thecyberpulse"
      expect(response.body).to include("What is The.CyberPul.se?")
    end
  end

  describe "GET /xeraen" do
    it "returns http success" do
      get "/xeraen"
      expect(response).to have_http_status(:success)
    end

    it "displays XERAEN content" do
      get "/xeraen"
      expect(response.body).to include("Latest Release")
    end
  end

  describe "GET /xeraen/linkz" do
    it "returns http success" do
      get "/xeraen/linkz"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /sector/x" do
    it "returns http success" do
      get "/sector/x"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /system_rot" do
    let!(:artist) { create(:artist, name: "System Rot", slug: "system_rot") }
    let!(:album) { create(:album, artist: artist, name: "Street Level EP") }
    let!(:track) { create(:track, artist: artist, album: album, title: "Concrete Manifesto") }

    it "returns http success" do
      get "/system_rot"
      expect(response).to have_http_status(:success)
    end

    it "displays System Rot content" do
      get "/system_rot"
      expect(response.body).to include("SYSTEM ROT")
      expect(response.body).to include("WE WERE HERE")
    end

    it "loads artist and tracks" do
      get "/system_rot"
      expect(assigns(:artist)).to eq(artist)
      expect(assigns(:tracks)).to include(track)
    end
  end

  describe "GET /wavelength_zero" do
    let!(:artist) { create(:artist, name: "Wavelength Zero", slug: "wavelength_zero") }
    let!(:album) { create(:album, artist: artist, name: "Zero Light EP") }
    let!(:track) { create(:track, artist: artist, album: album, title: "Prism Break") }

    it "returns http success" do
      get "/wavelength_zero"
      expect(response).to have_http_status(:success)
    end

    it "displays Wavelength Zero content" do
      get "/wavelength_zero"
      expect(response.body).to include("WAVELENGTH ZERO")
      expect(response.body).to include("felt something real")
    end

    it "loads artist and tracks" do
      get "/wavelength_zero"
      expect(assigns(:artist)).to eq(artist)
      expect(assigns(:tracks)).to include(track)
    end
  end

  describe "GET /voiceprint" do
    let!(:artist) { create(:artist, name: "Voiceprint", slug: "voiceprint") }
    let!(:album) { create(:album, artist: artist, name: "Audio Archive EP") }
    let!(:track) { create(:track, artist: artist, album: album, title: "Sample 1847") }

    it "returns http success" do
      get "/voiceprint"
      expect(response).to have_http_status(:success)
    end

    it "displays Voiceprint content" do
      get "/voiceprint"
      expect(response.body).to include("VOICEPRINT")
      expect(response.body).to include("authentic human")
    end

    it "loads artist and tracks" do
      get "/voiceprint"
      expect(assigns(:artist)).to eq(artist)
      expect(assigns(:tracks)).to include(track)
    end
  end

  describe "GET /temporal_blue_drift" do
    let!(:artist) { create(:artist, name: "Temporal Blue Drift", slug: "temporal_blue_drift") }
    let!(:album) { create(:album, artist: artist, name: "Chronologos EP") }
    let!(:track) { create(:track, artist: artist, album: album, title: "Chronology Fracture") }

    it "returns http success" do
      get "/temporal_blue_drift"
      expect(response).to have_http_status(:success)
    end

    it "displays Temporal Blue Drift content" do
      get "/temporal_blue_drift"
      expect(response.body).to include("Ashlinn—")
      expect(response.body).to include("love you across an impossible distance")
    end

    it "loads artist and tracks" do
      get "/temporal_blue_drift"
      expect(assigns(:artist)).to eq(artist)
      expect(assigns(:tracks)).to include(track)
    end
  end
end
