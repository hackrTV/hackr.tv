require "rails_helper"

RSpec.describe Api::ReleasesController, type: :controller do
  let!(:artist) { create(:artist) }
  let!(:release) { create(:release, artist: artist, slug: "test-release", coming_soon: false) }

  describe "POST #viewed" do
    context "with no logged-in hackr" do
      it "returns 204 and creates no view" do
        expect {
          post :viewed, params: {id: release.slug}, format: :json
        }.not_to change { HackrPageView.count }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "records a release view" do
        expect {
          post :viewed, params: {id: release.slug}, format: :json
        }.to change { HackrPageView.where(page_type: "release", resource_id: release.id).count }.by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "is idempotent per hackr+release" do
        post :viewed, params: {id: release.slug}, format: :json
        expect {
          post :viewed, params: {id: release.slug}, format: :json
        }.not_to change { HackrPageView.count }
      end

      it "refuses coming_soon releases" do
        coming = create(:release, artist: artist, slug: "teaser", coming_soon: true)

        post :viewed, params: {id: coming.slug}, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(HackrPageView.count).to eq(0)
      end

      it "returns 404 for an unknown slug" do
        post :viewed, params: {id: "no-such-release"}, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
