require "rails_helper"

RSpec.describe Api::ArtistsController, type: :controller do
  let!(:artist) { create(:artist, slug: "system-rot", name: "System Rot") }

  shared_examples "a page_view tracking endpoint" do |action_name, page_type:|
    context "with no logged-in hackr" do
      it "returns 204 and creates no view record" do
        expect {
          post action_name, params: {id: artist.slug}, format: :json
        }.not_to change { HackrPageView.count }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "records a #{page_type} view row" do
        expect {
          post action_name, params: {id: artist.slug}, format: :json
        }.to change { HackrPageView.where(page_type: page_type, resource_id: artist.id).count }.by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "is idempotent per hackr+resource" do
        post action_name, params: {id: artist.slug}, format: :json
        expect {
          post action_name, params: {id: artist.slug}, format: :json
        }.not_to change { HackrPageView.count }
      end

      it "returns 404 for an unknown artist slug" do
        post action_name, params: {id: "no-such-band"}, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #bio_viewed" do
    it_behaves_like "a page_view tracking endpoint", :bio_viewed, page_type: "bio"
  end

  describe "POST #release_index_viewed" do
    it_behaves_like "a page_view tracking endpoint", :release_index_viewed, page_type: "release_index"
  end

  describe "bio_viewed and release_index_viewed write to different page_type rows for the same artist" do
    let(:hackr) { create(:grid_hackr) }
    before { session[:grid_hackr_id] = hackr.id }

    it "records both side-by-side without collision" do
      post :bio_viewed, params: {id: artist.slug}, format: :json
      post :release_index_viewed, params: {id: artist.slug}, format: :json

      rows = HackrPageView.where(grid_hackr: hackr, resource_id: artist.id).pluck(:page_type).sort
      expect(rows).to eq(%w[bio release_index])
    end
  end
end
