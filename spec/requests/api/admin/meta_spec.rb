require "rails_helper"

RSpec.describe "Api::Admin::Meta", type: :request do
  before { ENV["HACKR_ADMIN_API_TOKEN"] = admin_token }
  after { ENV.delete("HACKR_ADMIN_API_TOKEN") }

  describe "GET /api/admin/capabilities" do
    it "returns all capability flags" do
      get "/api/admin/capabilities", headers: admin_headers
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

  describe "GET /api/admin/rate_limit" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(memory_store) }

    it "returns rate limit status" do
      get "/api/admin/rate_limit", headers: admin_headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      rl = body["rate_limit"]
      expect(rl["limit"]).to eq(125)
      expect(rl["remaining"]).to be <= 125
      expect(rl["resets_at"]).to be_present
    end
  end
end
