require "rails_helper"

# Dedicated spec for the `watch` action — split into its own file so
# the existing `hackr_streams_controller_spec.rb` (pre-existing
# coverage for show/index/vod_show) remains focused on those actions.
RSpec.describe Api::HackrStreamsController, type: :controller do
  let!(:artist) { create(:artist, slug: "thecyberpulse") }
  let!(:stream) { create(:hackr_stream, artist: artist, title: "Test VOD") }

  describe "POST #watch" do
    context "with no logged-in hackr" do
      it "returns 204 and creates no watch record" do
        expect {
          post :watch, params: {artist_slug: artist.slug, id: stream.id}, format: :json
        }.not_to change { HackrVodWatch.count }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "records a vod watch" do
        expect {
          post :watch, params: {artist_slug: artist.slug, id: stream.id}, format: :json
        }.to change { HackrVodWatch.count }.by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "is idempotent for the same hackr+stream" do
        post :watch, params: {artist_slug: artist.slug, id: stream.id}, format: :json
        expect {
          post :watch, params: {artist_slug: artist.slug, id: stream.id}, format: :json
        }.not_to change { HackrVodWatch.count }
      end

      it "returns 404 for an unknown artist slug" do
        post :watch, params: {artist_slug: "nobody", id: stream.id}, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for an unknown stream id" do
        post :watch, params: {artist_slug: artist.slug, id: 999_999}, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
