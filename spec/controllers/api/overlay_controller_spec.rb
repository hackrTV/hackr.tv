require "rails_helper"

RSpec.describe Api::OverlayController, type: :controller do
  let(:artist) { create(:artist) }
  let(:track) { create(:track, artist: artist) }

  before do
    allow(ActionCable.server).to receive(:broadcast)
  end

  describe "POST #set_now_playing" do
    context "with track_id" do
      it "sets the track" do
        post :set_now_playing, params: {track_id: track.id}, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["now_playing"]["track_id"]).to eq(track.id)
        expect(json["now_playing"]["title"]).to eq(track.title)
      end

      it "sets paused state" do
        post :set_now_playing, params: {track_id: track.id, paused: true}, format: :json

        json = JSON.parse(response.body)
        expect(json["now_playing"]["paused"]).to be true
      end

      it "broadcasts update" do
        expect(ActionCable.server).to receive(:broadcast).with("overlay_updates", hash_including(type: "now_playing_changed"))
        post :set_now_playing, params: {track_id: track.id}, format: :json
      end

      it "returns 404 for non-existent track" do
        post :set_now_playing, params: {track_id: 99999}, format: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to include("Track not found")
      end
    end

    context "with paused only (no track_id)" do
      before do
        OverlayNowPlaying.set_track!(track)
      end

      it "updates paused state for current track" do
        post :set_now_playing, params: {paused: true}, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["paused"]).to be true
      end

      it "broadcasts update" do
        expect(ActionCable.server).to receive(:broadcast).with("overlay_updates", hash_including(type: "now_playing_changed"))
        post :set_now_playing, params: {paused: true}, format: :json
      end
    end

    context "with clear parameter" do
      before do
        OverlayNowPlaying.set_track!(track)
      end

      it "clears now playing" do
        post :set_now_playing, params: {clear: true}, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["now_playing"]).to be_nil
      end

      it "broadcasts update" do
        expect(ActionCable.server).to receive(:broadcast).with("overlay_updates", hash_including(type: "now_playing_changed"))
        post :set_now_playing, params: {clear: true}, format: :json
      end
    end

    context "with no valid parameters" do
      it "returns bad request" do
        post :set_now_playing, format: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to include("Missing")
      end
    end
  end
end
