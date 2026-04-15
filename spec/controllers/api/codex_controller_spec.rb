require "rails_helper"

RSpec.describe Api::CodexController, type: :controller do
  describe "POST #mark_read" do
    let!(:entry) { create(:codex_entry, slug: "synthia", name: "Synthia", published: true) }

    context "with no logged-in hackr" do
      it "returns 204 and creates no read record" do
        expect {
          post :mark_read, params: {slug: entry.slug}, format: :json
        }.not_to change { CodexEntryRead.count }
        expect(response).to have_http_status(:no_content)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "records a read" do
        expect {
          post :mark_read, params: {slug: entry.slug}, format: :json
        }.to change { CodexEntryRead.count }.by(1)
        expect(response).to have_http_status(:no_content)
      end

      it "is idempotent for the same entry" do
        post :mark_read, params: {slug: entry.slug}, format: :json
        expect {
          post :mark_read, params: {slug: entry.slug}, format: :json
        }.not_to change { CodexEntryRead.count }
      end

      it "returns 404 for an unknown slug" do
        post :mark_read, params: {slug: "does-not-exist"}, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "refuses to mark an unpublished entry as read" do
        draft = create(:codex_entry, slug: "draft-entry", published: false)
        post :mark_read, params: {slug: draft.slug}, format: :json
        expect(response).to have_http_status(:not_found)
        expect(CodexEntryRead.where(codex_entry_id: draft.id).count).to eq(0)
      end
    end
  end
end
