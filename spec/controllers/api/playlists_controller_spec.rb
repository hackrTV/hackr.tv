require "rails_helper"

RSpec.describe Api::PlaylistsController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:other_hackr) { create(:grid_hackr) }

  describe "GET #index" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns user's playlists" do
        create(:playlist, grid_hackr: hackr, name: "My Playlist 1")
        create(:playlist, grid_hackr: hackr, name: "My Playlist 2")
        create(:playlist, grid_hackr: other_hackr, name: "Other's Playlist")

        get :index, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        expect(json.map { |p| p["name"] }).to match_array(["My Playlist 1", "My Playlist 2"])
      end

      it "includes track count in response" do
        playlist = create(:playlist, grid_hackr: hackr)
        artist = create(:artist)
        track = create(:track, artist: artist)
        create(:playlist_track, playlist: playlist, track: track)

        get :index, format: :json

        json = JSON.parse(response.body)
        expect(json.first["track_count"]).to eq(1)
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        get :index, format: :json

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Authentication required")
      end
    end
  end

  describe "GET #show" do
    context "when authenticated and owns playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns playlist with tracks" do
        playlist = create(:playlist, grid_hackr: hackr, name: "Test Playlist")
        artist = create(:artist)
        track1 = create(:track, artist: artist, title: "Track 1")
        track2 = create(:track, artist: artist, title: "Track 2")
        create(:playlist_track, playlist: playlist, track: track1, position: 1)
        create(:playlist_track, playlist: playlist, track: track2, position: 2)

        get :show, params: {id: playlist.id}, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Test Playlist")
        expect(json["tracks"].length).to eq(2)
        expect(json["tracks"][0]["title"]).to eq("Track 1")
        expect(json["tracks"][1]["title"]).to eq("Track 2")
      end

      it "includes playlist_track id in track data" do
        playlist = create(:playlist, grid_hackr: hackr)
        artist = create(:artist)
        track = create(:track, artist: artist)
        pt = create(:playlist_track, playlist: playlist, track: track)

        get :show, params: {id: playlist.id}, format: :json

        json = JSON.parse(response.body)
        expect(json["tracks"][0]["id"]).to eq(pt.id)
        expect(json["tracks"][0]["track_id"]).to eq(track.id)
      end
    end

    context "when trying to view another user's private playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        other_playlist = create(:playlist, grid_hackr: other_hackr, is_public: false)

        get :show, params: {id: other_playlist.id}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        playlist = create(:playlist, grid_hackr: hackr)

        get :show, params: {id: playlist.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #create" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "creates a new playlist" do
        expect {
          post :create, params: {playlist: {name: "New Playlist", description: "Test"}}, format: :json
        }.to change(Playlist, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["playlist"]["name"]).to eq("New Playlist")
      end

      it "generates a share token" do
        post :create, params: {playlist: {name: "New Playlist"}}, format: :json

        json = JSON.parse(response.body)
        expect(json["playlist"]["share_token"]).to be_present
      end

      it "returns error for invalid data" do
        post :create, params: {playlist: {name: ""}}, format: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to be_present
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        post :create, params: {playlist: {name: "New Playlist"}}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH #update" do
    context "when authenticated and owns playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "updates playlist" do
        playlist = create(:playlist, grid_hackr: hackr, name: "Old Name", is_public: false)

        patch :update, params: {id: playlist.id, playlist: {name: "New Name", is_public: true}}, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["playlist"]["name"]).to eq("New Name")
        expect(json["playlist"]["is_public"]).to be true

        playlist.reload
        expect(playlist.name).to eq("New Name")
        expect(playlist.is_public).to be true
      end

      it "returns error for invalid data" do
        playlist = create(:playlist, grid_hackr: hackr)

        patch :update, params: {id: playlist.id, playlist: {name: ""}}, format: :json

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when trying to update another user's playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        other_playlist = create(:playlist, grid_hackr: other_hackr)

        patch :update, params: {id: other_playlist.id, playlist: {name: "Hacked"}}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when authenticated and owns playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "deletes playlist" do
        playlist = create(:playlist, grid_hackr: hackr)

        expect {
          delete :destroy, params: {id: playlist.id}, format: :json
        }.to change(Playlist, :count).by(-1)

        expect(response).to have_http_status(:success)
      end

      it "cascades delete to playlist_tracks" do
        playlist = create(:playlist, grid_hackr: hackr)
        artist = create(:artist)
        track = create(:track, artist: artist)
        create(:playlist_track, playlist: playlist, track: track)

        expect {
          delete :destroy, params: {id: playlist.id}, format: :json
        }.to change(PlaylistTrack, :count).by(-1)
      end
    end

    context "when trying to delete another user's playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        other_playlist = create(:playlist, grid_hackr: other_hackr)

        delete :destroy, params: {id: other_playlist.id}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST #reorder" do
    let(:artist) { create(:artist) }

    context "when authenticated and owns playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "reorders tracks in playlist" do
        playlist = create(:playlist, grid_hackr: hackr)
        track1 = create(:track, artist: artist)
        track2 = create(:track, artist: artist)
        track3 = create(:track, artist: artist)

        pt1 = create(:playlist_track, playlist: playlist, track: track1, position: 1)
        pt2 = create(:playlist_track, playlist: playlist, track: track2, position: 2)
        pt3 = create(:playlist_track, playlist: playlist, track: track3, position: 3)

        # Reorder to: track3, track1, track2
        post :reorder, params: {
          id: playlist.id,
          track_ids: [track3.id, track1.id, track2.id]
        }, format: :json

        expect(response).to have_http_status(:success)

        pt1.reload
        pt2.reload
        pt3.reload
        expect(pt3.position).to eq(1)
        expect(pt1.position).to eq(2)
        expect(pt2.position).to eq(3)
      end
    end

    context "when trying to reorder another user's playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        other_playlist = create(:playlist, grid_hackr: other_hackr)

        post :reorder, params: {id: other_playlist.id, track_ids: []}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
