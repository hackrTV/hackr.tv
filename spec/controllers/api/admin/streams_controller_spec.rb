require "rails_helper"

RSpec.describe Api::Admin::StreamsController, type: :controller do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }

  before do
    request.headers["Authorization"] = "Bearer #{admin_hackr.hackr_alias}:#{raw_token}"
  end

  describe "GET #status" do
    context "when a stream is live" do
      it "returns stream info with is_live: true" do
        artist = create(:artist)
        stream = create(:hackr_stream, :live, artist: artist)

        get :status
        body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(body["is_live"]).to be true
        expect(body["stream"]["id"]).to eq(stream.id)
        expect(body["stream"]["artist"]["slug"]).to eq(artist.slug)
      end
    end

    context "when no stream is live" do
      it "returns is_live: false" do
        get :status
        body = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(body["is_live"]).to be false
        expect(body["stream"]).to be_nil
      end
    end
  end

  describe "POST #go_live" do
    let(:artist) { create(:artist) }

    it "creates a new live stream" do
      post :go_live, params: {artist_slug: artist.slug, url: "https://youtube.com/live/abc12345678", title: "Test Stream"}

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["stream"]["artist"]["slug"]).to eq(artist.slug)
      expect(body["stream"]["title"]).to eq("Test Stream")
    end

    it "ends existing live streams before going live" do
      existing = create(:hackr_stream, :live, artist: artist)

      post :go_live, params: {artist_slug: artist.slug, url: "https://youtube.com/live/abc12345678"}

      existing.reload
      expect(existing.is_live).to be false
      expect(existing.ended_at).to be_present
    end

    it "converts YouTube URLs to embed format" do
      post :go_live, params: {artist_slug: artist.slug, url: "https://www.youtube.com/watch?v=abc12345678"}

      body = JSON.parse(response.body)
      expect(body["stream"]["live_url"]).to eq("https://www.youtube.com/embed/abc12345678")
    end

    it "returns 404 for unknown artist" do
      post :go_live, params: {artist_slug: "nonexistent", url: "https://example.com/stream"}
      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when URL is missing" do
      post :go_live, params: {artist_slug: artist.slug}
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST #end_stream" do
    let(:artist) { create(:artist) }

    it "ends the live stream" do
      stream = create(:hackr_stream, :live, artist: artist)

      post :end_stream, params: {artist_slug: artist.slug}

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(stream.reload.is_live).to be false
    end

    it "returns 404 for unknown artist" do
      post :end_stream, params: {artist_slug: "nonexistent"}
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when artist has no live stream" do
      post :end_stream, params: {artist_slug: artist.slug}
      expect(response).to have_http_status(:not_found)

      body = JSON.parse(response.body)
      expect(body["error"]).to include("No live stream")
    end
  end
end
