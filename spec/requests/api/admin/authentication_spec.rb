require "rails_helper"

RSpec.describe "Api::Admin Authentication", type: :request do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }
  let(:valid_headers) { admin_headers_for(admin_hackr, raw_token) }

  describe "GET /api/admin/capabilities" do
    it "succeeds with valid bearer token" do
      get "/api/admin/capabilities", headers: valid_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without Authorization header" do
      get "/api/admin/capabilities"
      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["success"]).to be false
      expect(body["error"]).to include("Missing or invalid")
    end

    it "returns 401 with invalid token" do
      get "/api/admin/capabilities", headers: {"Authorization" => "Bearer #{admin_hackr.hackr_alias}:bad_token"}
      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Invalid admin token")
    end

    it "returns 401 with non-Bearer scheme" do
      get "/api/admin/capabilities", headers: {"Authorization" => "Token #{admin_bearer_token(admin_hackr, raw_token)}"}
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with invalid format (no colon separator)" do
      get "/api/admin/capabilities", headers: {"Authorization" => "Bearer just_a_token"}
      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Invalid token format")
    end

    it "returns 403 when hackr is not an admin" do
      operative = create(:grid_hackr, role: "operative")
      operative_token = operative.generate_api_token!

      get "/api/admin/capabilities", headers: admin_headers_for(operative, operative_token)
      expect(response).to have_http_status(:forbidden)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("Admin privileges required")
    end

    context "rate limiting", :rate_limit do
      let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

      before { allow(Rails).to receive(:cache).and_return(memory_store) }

      it "includes rate limit headers" do
        get "/api/admin/capabilities", headers: valid_headers
        expect(response.headers["X-RateLimit-Limit"]).to eq("125")
        expect(response.headers["X-RateLimit-Remaining"]).to be_present
        expect(response.headers["X-RateLimit-Reset"]).to be_present
      end

      it "returns 429 when rate limit is exceeded" do
        window_key = "admin_api_rate:#{admin_hackr.hackr_alias}:#{Time.current.strftime("%Y%m%d%H%M")}"
        memory_store.write(window_key, 125, expires_in: 2.minutes)

        get "/api/admin/capabilities", headers: valid_headers
        expect(response).to have_http_status(:too_many_requests)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("Rate limit exceeded")
      end
    end
  end
end
