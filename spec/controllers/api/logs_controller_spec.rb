require "rails_helper"

RSpec.describe Api::LogsController, type: :controller do
  describe "POST #mark_read" do
    let!(:log) { create(:hackr_log, :published, slug: "signal-test") }

    context "with no logged-in hackr" do
      it "returns 204 and does not create a read record" do
        expect {
          post :mark_read, params: {id: log.slug}, format: :json
        }.not_to change { HackrLogRead.count }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "records a read" do
        expect {
          post :mark_read, params: {id: log.slug}, format: :json
        }.to change { HackrLogRead.count }.by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "is idempotent" do
        post :mark_read, params: {id: log.slug}, format: :json
        expect {
          post :mark_read, params: {id: log.slug}, format: :json
        }.not_to change { HackrLogRead.count }
      end

      it "returns 404 for an unknown slug" do
        post :mark_read, params: {id: "does-not-exist"}, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "refuses to mark an unpublished log as read" do
        draft = create(:hackr_log, slug: "draft", published: false)
        post :mark_read, params: {id: draft.slug}, format: :json
        expect(response).to have_http_status(:not_found)
        expect(HackrLogRead.where(hackr_log_id: draft.id).count).to eq(0)
      end
    end
  end
end
