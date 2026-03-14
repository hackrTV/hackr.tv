require "rails_helper"

RSpec.describe Api::Admin::CodeController, type: :controller do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }

  before do
    request.headers["Authorization"] = "Bearer #{admin_hackr.hackr_alias}:#{raw_token}"
  end

  describe "POST #sync" do
    it "enqueues a CodeSyncJob" do
      expect {
        post :sync, format: :json
      }.to have_enqueued_job(CodeSyncJob)
    end

    it "returns success response" do
      post :sync, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(json["message"]).to eq("Code sync job enqueued")
    end
  end

  context "without authentication" do
    before do
      request.headers["Authorization"] = nil
    end

    it "returns 401 unauthorized" do
      post :sync, format: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
