require "rails_helper"

RSpec.describe "Api::Admin::Meta", type: :request do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }
  let(:valid_headers) { admin_headers_for(admin_hackr, raw_token) }

  describe "GET /api/admin/capabilities" do
    it "returns all capability flags" do
      get "/api/admin/capabilities", headers: valid_headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      caps = body["capabilities"]
      expect(caps).to include(
        "streams" => true,
        "hackr_logs" => true,
        "pulses" => true,
        "uplink" => true,
        "grid" => false,
        "meta" => true
      )
    end
  end

  describe "GET /api/admin/stats" do
    it "returns all system stats with correct keys" do
      get "/api/admin/stats", headers: valid_headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["success"]).to be true

      stats = body["stats"]
      expect(stats).to include(
        "online_hackrs", "total_emails_sent", "emails_sent_24h",
        "emails_sent_30d", "artists", "tracks", "hackr_logs", "codex_entries"
      )
    end

    it "returns accurate email counts across time windows" do
      create(:sent_email, created_at: 1.hour.ago)
      create(:sent_email, created_at: 2.hours.ago)
      create(:sent_email, created_at: 10.days.ago)
      create(:sent_email, created_at: 60.days.ago)

      get "/api/admin/stats", headers: valid_headers
      stats = JSON.parse(response.body)["stats"]

      expect(stats["total_emails_sent"]).to eq(4)
      expect(stats["emails_sent_24h"]).to eq(2)
      expect(stats["emails_sent_30d"]).to eq(3)
    end
  end

  describe "GET /api/admin/rate_limit" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(memory_store) }

    it "returns rate limit status" do
      get "/api/admin/rate_limit", headers: valid_headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      rl = body["rate_limit"]
      expect(rl["limit"]).to eq(125)
      expect(rl["remaining"]).to be <= 125
      expect(rl["resets_at"]).to be_present
    end
  end
end
