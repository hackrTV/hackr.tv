require "rails_helper"

# Phase 4: Hotwire playlist pages (replace PlaylistsPage / PlaylistDetailPage /
# SharedPlaylistPage). Reorder stays on Api::PlaylistsController#reorder.
RSpec.describe "Playlist pages", type: :request do
  let(:hackr) { create(:grid_hackr, password: "hackthegrid") }
  let(:artist) { create(:artist) }
  let(:release) { create(:release, artist: artist) }

  def login
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  describe "GET /fm/playlists" do
    it "requires login" do
      get "/fm/playlists"
      expect(response).to redirect_to("/grid/login")
    end

    it "lists the hackr's playlists with create dialog" do
      login
      create(:playlist, grid_hackr: hackr, name: "Night Drive")

      get "/fm/playlists"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("MY PLAYLISTS")
      expect(response.body).to include("Night Drive")
      expect(response.body).to include("CREATE PLAYLIST")
      expect(response.body).to include('data-controller="dialog"')
    end
  end

  describe "POST /fm/playlists" do
    it "creates and redirects to the new playlist" do
      login
      post "/fm/playlists", params: {playlist: {name: "Fresh Cuts", description: "new stuff"}}

      playlist = hackr.playlists.last
      expect(playlist.name).to eq("Fresh Cuts")
      expect(response).to redirect_to("/fm/playlists/#{playlist.id}")
      expect(response).to have_http_status(:see_other)
    end

    it "redirects back with an error for invalid params" do
      login
      post "/fm/playlists", params: {playlist: {name: ""}}

      expect(response).to redirect_to("/fm/playlists")
      expect(flash[:error]).to include("Name")
    end
  end

  describe "GET /fm/playlists/:id" do
    it "renders own playlist with tracks, reorder wiring, and share link" do
      login
      playlist = create(:playlist, grid_hackr: hackr, name: "Synth Set", is_public: true)
      track = create(:track, :with_audio, artist: artist, release: release, title: "Waveform")
      create(:playlist_track, playlist: playlist, track: track)

      get "/fm/playlists/#{playlist.id}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Synth Set")
      expect(response.body).to include("Waveform")
      expect(response.body).to include('data-controller="playlist-reorder"')
      expect(response.body).to include("/api/playlists/#{playlist.id}/reorder")
      expect(response.body).to include("/shared/#{playlist.share_token}")
      expect(response.body).to include("data-player-url=")
    end

    it "redirects for someone else's playlist" do
      login
      other = create(:grid_hackr)
      playlist = create(:playlist, grid_hackr: other)

      get "/fm/playlists/#{playlist.id}"

      expect(response).to redirect_to("/fm/playlists")
    end
  end

  describe "PATCH /fm/playlists/:id" do
    it "updates and redirects back to the playlist" do
      login
      playlist = create(:playlist, grid_hackr: hackr, name: "Old Name")

      patch "/fm/playlists/#{playlist.id}", params: {playlist: {name: "New Name", is_public: "true"}}

      expect(response).to redirect_to("/fm/playlists/#{playlist.id}")
      expect(playlist.reload.name).to eq("New Name")
      expect(playlist.is_public).to be(true)
    end
  end

  describe "DELETE /fm/playlists/:id" do
    it "deletes and redirects to the index" do
      login
      playlist = create(:playlist, grid_hackr: hackr)

      delete "/fm/playlists/#{playlist.id}"

      expect(response).to redirect_to("/fm/playlists")
      expect(Playlist.exists?(playlist.id)).to be(false)
    end
  end

  describe "DELETE /fm/playlists/:id/tracks/:playlist_track_id" do
    it "removes the track and redirects back" do
      login
      playlist = create(:playlist, grid_hackr: hackr)
      track = create(:track, :with_audio, artist: artist, release: release)
      playlist_track = create(:playlist_track, playlist: playlist, track: track)

      delete "/fm/playlists/#{playlist.id}/tracks/#{playlist_track.id}"

      expect(response).to redirect_to("/fm/playlists/#{playlist.id}")
      expect(PlaylistTrack.exists?(playlist_track.id)).to be(false)
    end
  end

  describe "GET /shared/:token" do
    it "renders a public playlist read-only" do
      playlist = create(:playlist, is_public: true, name: "Public Mix")
      track = create(:track, :with_audio, artist: artist, release: release, title: "Open Signal")
      create(:playlist_track, playlist: playlist, track: track)

      get "/shared/#{playlist.share_token}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("SHARED PLAYLIST")
      expect(response.body).to include("Public Mix")
      expect(response.body).to include("Open Signal")
      expect(response.body).not_to include("Remove")
      expect(response.body).not_to include("playlist-reorder")
    end

    it "404s for a private playlist's token" do
      playlist = create(:playlist, is_public: false)

      get "/shared/#{playlist.share_token}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
