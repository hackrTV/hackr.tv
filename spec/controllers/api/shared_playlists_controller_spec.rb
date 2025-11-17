require "rails_helper"

RSpec.describe Api::SharedPlaylistsController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:artist) { create(:artist) }

  describe "GET #show" do
    context "when playlist is public" do
      it "returns playlist without authentication" do
        playlist = create(:playlist, grid_hackr: hackr, name: "Public Playlist", is_public: true)
        track = create(:track, artist: artist, title: "Public Track")
        create(:playlist_track, playlist: playlist, track: track)

        get :show, params: {share_token: playlist.share_token}, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Public Playlist")
        expect(json["tracks"].length).to eq(1)
        expect(json["tracks"][0]["title"]).to eq("Public Track")
      end

      it "includes owner hackr alias" do
        playlist = create(:playlist, grid_hackr: hackr, is_public: true)

        get :show, params: {share_token: playlist.share_token}, format: :json

        json = JSON.parse(response.body)
        expect(json["owner"]["hackr_alias"]).to eq(hackr.hackr_alias)
      end

      it "does not expose sensitive owner info" do
        playlist = create(:playlist, grid_hackr: hackr, is_public: true)

        get :show, params: {share_token: playlist.share_token}, format: :json

        json = JSON.parse(response.body)
        expect(json["owner"]["password_digest"]).to be_nil
        expect(json["owner"]["role"]).to be_nil
      end
    end

    context "when playlist is private" do
      it "returns 404 not found" do
        playlist = create(:playlist, grid_hackr: hackr, is_public: false)

        get :show, params: {share_token: playlist.share_token}, format: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("not found or not public")
      end
    end

    context "when share token is invalid" do
      it "returns 404 not found" do
        get :show, params: {share_token: "invalid_token"}, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
