require "rails_helper"

# Dedicated spec for the `tune_in` action — split from the pre-existing
# `radio_controller_spec.rb` which focuses on index/station_playlists.
RSpec.describe Api::RadioController, type: :controller do
  let!(:station) { create(:radio_station, hidden: false) }

  describe "POST #tune_in" do
    context "with no logged-in hackr" do
      it "returns 204 and creates no tune record" do
        expect {
          post :tune_in, params: {id: station.id}, format: :json
        }.not_to change { HackrRadioTune.count }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "records a tune_in" do
        expect {
          post :tune_in, params: {id: station.id}, format: :json
        }.to change { HackrRadioTune.count }.by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "is idempotent for the same hackr+station" do
        post :tune_in, params: {id: station.id}, format: :json
        expect {
          post :tune_in, params: {id: station.id}, format: :json
        }.not_to change { HackrRadioTune.count }
      end

      it "returns 404 for a hidden station" do
        hidden = create(:radio_station, hidden: true)
        post :tune_in, params: {id: hidden.id}, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for an unknown station id" do
        post :tune_in, params: {id: 999_999}, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
