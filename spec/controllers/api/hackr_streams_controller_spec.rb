require "rails_helper"

RSpec.describe Api::HackrStreamsController, type: :controller do
  describe "GET #show" do
    context "when there is a live stream" do
      let(:artist) { create(:artist, :xeraen) }
      let!(:stream) do
        create(:hackr_stream, :live,
          artist: artist,
          title: "Live Test Stream")
      end

      it "returns the current live stream" do
        get :show, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["is_live"]).to be true
        expect(json["title"]).to eq("Live Test Stream")
      end

      it "includes artist information" do
        get :show, format: :json

        json = JSON.parse(response.body)
        expect(json["artist"]["name"]).to eq("XERAEN")
        expect(json["artist"]["slug"]).to eq("xeraen")
      end
    end

    context "when there is no live stream" do
      it "returns is_live: false" do
        get :show, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["is_live"]).to be false
      end
    end
  end

  describe "GET #index" do
    let(:artist) { create(:artist, :xeraen) }

    context "when artist has VODs" do
      let!(:vod1) do
        create(:hackr_stream, :livestream_with_vod,
          artist: artist,
          title: "Stream 1",
          started_at: 2.days.ago,
          ended_at: 2.days.ago + 2.hours)
      end

      let!(:vod2) do
        create(:hackr_stream, :with_vod,
          artist: artist,
          title: "Stream 2",
          started_at: 1.day.ago,
          ended_at: 1.day.ago + 2.hours)
      end

      let!(:stream_without_vod) do
        create(:hackr_stream,
          artist: artist,
          title: "No VOD",
          vod_url: nil,
          started_at: 3.days.ago)
      end

      it "returns only streams with vod_url" do
        get :index, params: {artist_slug: "xeraen"}, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["vods"].length).to eq(2)
      end

      it "orders by started_at descending" do
        get :index, params: {artist_slug: "xeraen"}, format: :json

        json = JSON.parse(response.body)
        expect(json["vods"][0]["title"]).to eq("Stream 2") # More recent
        expect(json["vods"][1]["title"]).to eq("Stream 1") # Older
      end

      it "includes was_livestream flag based on live_url presence" do
        get :index, params: {artist_slug: "xeraen"}, format: :json

        json = JSON.parse(response.body)
        vod_with_livestream = json["vods"].find { |v| v["title"] == "Stream 1" }
        vod_without_livestream = json["vods"].find { |v| v["title"] == "Stream 2" }

        expect(vod_with_livestream["was_livestream"]).to be true
        expect(vod_without_livestream["was_livestream"]).to be false
      end

      it "includes artist information" do
        get :index, params: {artist_slug: "xeraen"}, format: :json

        json = JSON.parse(response.body)
        expect(json["artist"]["name"]).to eq("XERAEN")
        expect(json["artist"]["slug"]).to eq("xeraen")
      end

      it "includes all VOD attributes" do
        get :index, params: {artist_slug: "xeraen"}, format: :json

        json = JSON.parse(response.body)
        vod = json["vods"].first

        expect(vod).to have_key("id")
        expect(vod).to have_key("title")
        expect(vod).to have_key("vod_url")
        expect(vod).to have_key("live_url")
        expect(vod).to have_key("started_at")
        expect(vod).to have_key("ended_at")
        expect(vod).to have_key("was_livestream")
      end
    end

    context "when artist has no VODs" do
      before { artist } # ensure artist exists

      it "returns empty array" do
        get :index, params: {artist_slug: "xeraen"}, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["vods"]).to eq([])
      end
    end

    context "when artist does not exist" do
      it "returns 404" do
        get :index, params: {artist_slug: "nonexistent"}, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #vod_show" do
    let(:artist) { create(:artist, :thecyberpulse) }
    let!(:vod) do
      create(:hackr_stream, :livestream_with_vod,
        artist: artist,
        title: "Test VOD")
    end

    it "returns the VOD details" do
      get :vod_show, params: {artist_slug: "thecyberpulse", id: vod.id}, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["id"]).to eq(vod.id)
      expect(json["title"]).to eq("Test VOD")
      expect(json["was_livestream"]).to be true
    end

    it "includes artist information" do
      get :vod_show, params: {artist_slug: "thecyberpulse", id: vod.id}, format: :json

      json = JSON.parse(response.body)
      expect(json["artist"]["name"]).to eq("The.CyberPul.se")
      expect(json["artist"]["slug"]).to eq("thecyberpulse")
    end

    context "when VOD does not exist" do
      it "returns 404" do
        get :vod_show, params: {artist_slug: "thecyberpulse", id: 99999}, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when VOD belongs to different artist" do
      let(:other_artist) { create(:artist, :xeraen) }

      it "returns 404" do
        get :vod_show, params: {artist_slug: other_artist.slug, id: vod.id}, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
