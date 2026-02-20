require "rails_helper"

RSpec.describe "Api::Admin::Streams", type: :request do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }
  let(:valid_headers) { admin_headers_for(admin_hackr, raw_token) }

  describe "GET /api/admin/streams/status" do
    it "returns is_live: true when a stream is live" do
      artist = create(:artist)
      stream = create(:hackr_stream, :live, artist: artist)

      get "/api/admin/streams/status", headers: valid_headers
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(body["is_live"]).to be true
      expect(body["stream"]["id"]).to eq(stream.id)
      expect(body["stream"]["artist"]["name"]).to eq(artist.name)
    end

    it "returns is_live: false when no stream is live" do
      get "/api/admin/streams/status", headers: valid_headers
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(body["is_live"]).to be false
    end
  end

  describe "POST /api/admin/streams/go_live" do
    let(:artist) { create(:artist) }

    it "creates a new live stream" do
      post "/api/admin/streams/go_live",
        params: {artist_slug: artist.slug, url: "https://youtube.com/live/abc12345678", title: "Live Show"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["stream"]["title"]).to eq("Live Show")
    end

    it "ends existing live streams" do
      existing = create(:hackr_stream, :live, artist: artist)

      post "/api/admin/streams/go_live",
        params: {artist_slug: artist.slug, url: "https://youtube.com/live/abc12345678"},
        headers: valid_headers

      expect(existing.reload.is_live).to be false
    end

    it "returns 404 for unknown artist" do
      post "/api/admin/streams/go_live",
        params: {artist_slug: "nonexistent", url: "https://example.com/stream"},
        headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when URL is missing" do
      post "/api/admin/streams/go_live",
        params: {artist_slug: artist.slug},
        headers: valid_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/admin/streams/end_stream" do
    let(:artist) { create(:artist) }

    it "ends the artist's live stream" do
      stream = create(:hackr_stream, :live, artist: artist)

      post "/api/admin/streams/end_stream",
        params: {artist_slug: artist.slug},
        headers: valid_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(stream.reload.is_live).to be false
    end

    it "returns 404 when no live stream exists" do
      post "/api/admin/streams/end_stream",
        params: {artist_slug: artist.slug},
        headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for unknown artist" do
      post "/api/admin/streams/end_stream",
        params: {artist_slug: "nonexistent"},
        headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
