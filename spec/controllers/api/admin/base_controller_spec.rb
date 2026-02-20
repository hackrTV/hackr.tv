require "rails_helper"

RSpec.describe Api::Admin::BaseController, type: :controller do
  # Create a test controller that inherits from BaseController
  controller(Api::Admin::BaseController) do
    def index
      render json: {success: true, message: "ok"}
    end
  end

  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }

  before do
    routes.draw { get "index" => "api/admin/base#index" }
  end

  describe "authentication" do
    it "allows access with valid bearer token" do
      request.headers["Authorization"] = "Bearer #{admin_hackr.hackr_alias}:#{raw_token}"
      get :index
      expect(response).to have_http_status(:ok)
      expect(parsed_body["success"]).to be true
    end

    it "rejects requests without Authorization header" do
      get :index
      expect(response).to have_http_status(:unauthorized)
      expect(parsed_body["error"]).to include("Missing or invalid")
    end

    it "rejects requests with invalid token" do
      request.headers["Authorization"] = "Bearer #{admin_hackr.hackr_alias}:wrong_token"
      get :index
      expect(response).to have_http_status(:unauthorized)
      expect(parsed_body["error"]).to eq("Invalid admin token")
    end

    it "rejects requests with non-Bearer auth scheme" do
      request.headers["Authorization"] = "Basic #{admin_hackr.hackr_alias}:#{raw_token}"
      get :index
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with invalid format (no colon separator)" do
      request.headers["Authorization"] = "Bearer just_a_token"
      get :index
      expect(response).to have_http_status(:unauthorized)
      expect(parsed_body["error"]).to include("Invalid token format")
    end

    it "returns 403 when hackr is not an admin" do
      operative = create(:grid_hackr, role: "operative")
      operative_token = operative.generate_api_token!

      request.headers["Authorization"] = "Bearer #{operative.hackr_alias}:#{operative_token}"
      get :index
      expect(response).to have_http_status(:forbidden)
      expect(parsed_body["error"]).to include("Admin privileges required")
    end
  end

  describe "rate limiting" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      request.headers["Authorization"] = "Bearer #{admin_hackr.hackr_alias}:#{raw_token}"
      allow(Rails).to receive(:cache).and_return(memory_store)
    end

    it "sets rate limit headers on response" do
      get :index
      expect(response.headers["X-RateLimit-Limit"]).to eq("125")
      expect(response.headers["X-RateLimit-Remaining"]).to be_present
      expect(response.headers["X-RateLimit-Reset"]).to be_present
    end

    it "returns 429 when rate limit is exceeded" do
      window_key = "admin_api_rate:#{admin_hackr.hackr_alias}:#{Time.current.strftime("%Y%m%d%H%M")}"
      memory_store.write(window_key, 125, expires_in: 2.minutes)

      get :index
      expect(response).to have_http_status(:too_many_requests)
      expect(parsed_body["error"]).to include("Rate limit exceeded")
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
