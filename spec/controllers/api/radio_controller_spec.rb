require "rails_helper"

RSpec.describe Api::RadioController, type: :controller do
  describe "GET #index" do
    it "returns all radio stations ordered by position" do
      station3 = create(:radio_station, position: 2)
      station1 = create(:radio_station, position: 0)
      station2 = create(:radio_station, position: 1)

      get :index, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
      expect(json[0]["id"]).to eq(station1.id)
      expect(json[1]["id"]).to eq(station2.id)
      expect(json[2]["id"]).to eq(station3.id)
    end

    it "includes station attributes in response" do
      create(:radio_station,
        name: "Test Station",
        slug: "test-station",
        description: "Test description",
        genre: "Electronic",
        color: "purple-168",
        stream_url: "http://example.com/stream",
        position: 0)

      get :index, format: :json

      json = JSON.parse(response.body).first
      expect(json["name"]).to eq("Test Station")
      expect(json["slug"]).to eq("test-station")
      expect(json["description"]).to eq("Test description")
      expect(json["genre"]).to eq("Electronic")
      expect(json["color"]).to eq("purple-168")
      expect(json["stream_url"]).to eq("http://example.com/stream")
      expect(json["position"]).to eq(0)
    end

    it "includes associated playlists with track counts" do
      station = create(:radio_station)
      playlist1 = create(:playlist)
      playlist2 = create(:playlist)

      # Add tracks to playlists
      track1 = create(:track)
      track2 = create(:track)
      create(:playlist_track, playlist: playlist1, track: track1, position: 1)
      create(:playlist_track, playlist: playlist2, track: track2, position: 1)

      create(:radio_station_playlist, radio_station: station, playlist: playlist1, position: 1)
      create(:radio_station_playlist, radio_station: station, playlist: playlist2, position: 2)

      get :index, format: :json

      json = JSON.parse(response.body).first
      expect(json["playlists"].length).to eq(2)
      expect(json["playlists"][0]["id"]).to eq(playlist1.id)
      expect(json["playlists"][0]["track_count"]).to eq(1)
      expect(json["playlists"][1]["id"]).to eq(playlist2.id)
    end
  end

  describe "GET #station_playlists" do
    let(:station) { create(:radio_station) }
    let(:hackr) { create(:grid_hackr) }
    let(:playlist1) { create(:playlist, grid_hackr: hackr) }
    let(:playlist2) { create(:playlist, grid_hackr: hackr) }
    let(:track1) { create(:track) }
    let(:track2) { create(:track) }

    before do
      # Set up station with playlists
      create(:radio_station_playlist, radio_station: station, playlist: playlist1, position: 1)
      create(:radio_station_playlist, radio_station: station, playlist: playlist2, position: 2)

      # Add tracks to playlists
      create(:playlist_track, playlist: playlist1, track: track1, position: 1)
      create(:playlist_track, playlist: playlist2, track: track2, position: 1)
    end

    it "returns playlists for a station in position order" do
      get :station_playlists, params: {id: station.id}, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
      expect(json[0]["id"]).to eq(playlist1.id)
      expect(json[1]["id"]).to eq(playlist2.id)
    end

    it "does not require authentication" do
      # No session setup - should still work
      get :station_playlists, params: {id: station.id}, format: :json

      expect(response).to have_http_status(:ok)
    end

    it "includes playlist metadata" do
      get :station_playlists, params: {id: station.id}, format: :json

      json = JSON.parse(response.body).first
      expect(json["name"]).to eq(playlist1.name)
      expect(json["description"]).to eq(playlist1.description)
      expect(json["is_public"]).to eq(playlist1.is_public)
      expect(json["track_count"]).to eq(1)
    end

    it "includes tracks with full details" do
      get :station_playlists, params: {id: station.id}, format: :json

      json = JSON.parse(response.body).first
      track_json = json["tracks"].first

      expect(track_json["track_id"]).to eq(track1.id)
      expect(track_json["title"]).to eq(track1.title)
      expect(track_json["slug"]).to eq(track1.slug)
      expect(track_json["track_number"]).to eq(track1.track_number)
      expect(track_json["duration"]).to eq(track1.duration)
      expect(track_json["position"]).to eq(1)
    end

    it "includes artist information in tracks" do
      get :station_playlists, params: {id: station.id}, format: :json

      json = JSON.parse(response.body).first
      track_json = json["tracks"].first
      artist_json = track_json["artist"]

      expect(artist_json["id"]).to eq(track1.artist.id)
      expect(artist_json["name"]).to eq(track1.artist.name)
      expect(artist_json["slug"]).to eq(track1.artist.slug)
    end

    it "includes release information when track has release" do
      release = create(:release, artist: track1.artist)
      track1.update(release: release)

      get :station_playlists, params: {id: station.id}, format: :json

      json = JSON.parse(response.body).first
      track_json = json["tracks"].first
      release_json = track_json["release"]

      expect(release_json).not_to be_nil
      expect(release_json["id"]).to eq(release.id)
      expect(release_json["name"]).to eq(release.name)
      expect(release_json["slug"]).to eq(release.slug)
    end

    it "includes audio_url when track has audio file" do
      # Track factory should handle audio file attachment
      # This test verifies the URL is included in response
      get :station_playlists, params: {id: station.id}, format: :json

      json = JSON.parse(response.body).first
      track_json = json["tracks"].first

      # audio_url should be present (even if nil for tracks without audio)
      expect(track_json).to have_key("audio_url")
    end

    it "includes cover_url when release has cover image" do
      release = create(:release, artist: track1.artist)
      track1.update(release: release)

      get :station_playlists, params: {id: station.id}, format: :json

      json = JSON.parse(response.body).first
      track_json = json["tracks"].first
      release_json = track_json["release"]

      # cover_url should be present in release
      expect(release_json).to have_key("cover_url")
    end

    it "orders tracks by position within each playlist" do
      track3 = create(:track)
      create(:playlist_track, playlist: playlist1, track: track3, position: 2)

      get :station_playlists, params: {id: station.id}, format: :json

      json = JSON.parse(response.body).first
      tracks = json["tracks"]

      expect(tracks.length).to eq(2)
      expect(tracks[0]["position"]).to eq(1)
      expect(tracks[1]["position"]).to eq(2)
    end

    it "returns 404 for non-existent station" do
      get :station_playlists, params: {id: 99999}, format: :json

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Radio station not found")
    end

    it "returns empty array for station with no playlists" do
      empty_station = create(:radio_station)

      get :station_playlists, params: {id: empty_station.id}, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it "includes playlists regardless of public/private status" do
      private_playlist = create(:playlist, grid_hackr: hackr, is_public: false)
      create(:radio_station_playlist, radio_station: station, playlist: private_playlist, position: 3)

      get :station_playlists, params: {id: station.id}, format: :json

      json = JSON.parse(response.body)
      expect(json.length).to eq(3) # 2 original + 1 private
      expect(json.any? { |p| p["id"] == private_playlist.id }).to be true
    end
  end
end
