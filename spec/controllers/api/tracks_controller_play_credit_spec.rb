require "rails_helper"

RSpec.describe Api::TracksController, type: :controller do
  describe "POST #play_credit" do
    let(:artist) { create(:artist) }
    let(:release) { create(:release, artist: artist, coming_soon: false) }
    let!(:track) { create(:track, artist: artist, release: release, slug: "test-track") }

    context "with no logged-in hackr" do
      it "returns 204 and creates no record" do
        expect {
          post :play_credit, params: {id: track.slug}, format: :json
        }.not_to change { GridHackrTrackPlay.count }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "records a play" do
        expect {
          post :play_credit, params: {id: track.slug}, format: :json
        }.to change { GridHackrTrackPlay.count }.by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "increments play_count on re-play" do
        post :play_credit, params: {id: track.slug}, format: :json
        post :play_credit, params: {id: track.slug}, format: :json

        record = GridHackrTrackPlay.find_by(grid_hackr: hackr, track: track)
        expect(record.play_count).to eq(2)
      end

      it "returns 404 for an unknown track" do
        post :play_credit, params: {id: "no-such-track"}, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "refuses to credit a coming_soon release's tracks" do
        coming = create(:release, artist: artist, coming_soon: true)
        teaser = create(:track, artist: artist, release: coming, slug: "teaser")

        post :play_credit, params: {id: teaser.slug}, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(GridHackrTrackPlay.count).to eq(0)
      end

      it "refuses to credit a track hidden from the pulse vault" do
        hidden = create(:track, artist: artist, release: release, slug: "hidden", show_in_pulse_vault: false)

        post :play_credit, params: {id: hidden.slug}, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(GridHackrTrackPlay.count).to eq(0)
      end
    end
  end
end
