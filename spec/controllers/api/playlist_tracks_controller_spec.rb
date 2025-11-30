require "rails_helper"

RSpec.describe Api::PlaylistTracksController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:other_hackr) { create(:grid_hackr) }
  let(:artist) { create(:artist) }

  describe "POST #create" do
    context "when authenticated and owns playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "adds track to playlist" do
        playlist = create(:playlist, grid_hackr: hackr)
        track = create(:track, artist: artist)

        expect {
          post :create, params: {playlist_id: playlist.id, track_id: track.id}, format: :json
        }.to change(PlaylistTrack, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end

      it "auto-assigns position" do
        playlist = create(:playlist, grid_hackr: hackr)
        track1 = create(:track, artist: artist)
        track2 = create(:track, artist: artist)

        post :create, params: {playlist_id: playlist.id, track_id: track1.id}, format: :json
        post :create, params: {playlist_id: playlist.id, track_id: track2.id}, format: :json

        expect(playlist.playlist_tracks.find_by(track: track1).position).to eq(1)
        expect(playlist.playlist_tracks.find_by(track: track2).position).to eq(2)
      end

      it "prevents duplicate tracks in playlist" do
        playlist = create(:playlist, grid_hackr: hackr)
        track = create(:track, artist: artist)
        create(:playlist_track, playlist: playlist, track: track)

        post :create, params: {playlist_id: playlist.id, track_id: track.id}, format: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("already in the playlist")
      end
    end

    context "when trying to add to another user's playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        other_playlist = create(:playlist, grid_hackr: other_hackr)
        track = create(:track, artist: artist)

        post :create, params: {playlist_id: other_playlist.id, track_id: track.id}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        playlist = create(:playlist, grid_hackr: hackr)
        track = create(:track, artist: artist)

        post :create, params: {playlist_id: playlist.id, track_id: track.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when authenticated and owns playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "removes track from playlist" do
        playlist = create(:playlist, grid_hackr: hackr)
        track = create(:track, artist: artist)
        playlist_track = create(:playlist_track, playlist: playlist, track: track)

        expect {
          delete :destroy, params: {playlist_id: playlist.id, id: playlist_track.id}, format: :json
        }.to change(PlaylistTrack, :count).by(-1)

        expect(response).to have_http_status(:success)
      end

      it "reorders remaining tracks after deletion" do
        playlist = create(:playlist, grid_hackr: hackr)
        track1 = create(:track, artist: artist)
        track2 = create(:track, artist: artist)
        track3 = create(:track, artist: artist)

        pt1 = create(:playlist_track, playlist: playlist, track: track1, position: 1)
        pt2 = create(:playlist_track, playlist: playlist, track: track2, position: 2)
        pt3 = create(:playlist_track, playlist: playlist, track: track3, position: 3)

        delete :destroy, params: {playlist_id: playlist.id, id: pt2.id}, format: :json

        pt1.reload
        pt3.reload
        expect(pt1.position).to eq(1)
        expect(pt3.position).to eq(2) # Should be decremented
      end
    end

    context "when trying to remove from another user's playlist" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        other_playlist = create(:playlist, grid_hackr: other_hackr)
        track = create(:track, artist: artist)
        playlist_track = create(:playlist_track, playlist: other_playlist, track: track)

        delete :destroy, params: {playlist_id: other_playlist.id, id: playlist_track.id}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
