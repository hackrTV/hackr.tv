require "rails_helper"

RSpec.describe Api::Admin::BaseController, type: :controller do
  # Create a test controller that inherits from BaseController
  controller(Api::Admin::BaseController) do
    def index
      render json: {success: true, message: "ok"}
    end
  end

  before do
    ENV["HACKR_ADMIN_API_TOKEN"] = admin_token
    routes.draw { get "index" => "api/admin/base#index" }
  end

  after { ENV.delete("HACKR_ADMIN_API_TOKEN") }

  describe "authentication" do
    it "allows access with valid bearer token" do
      request.headers["Authorization"] = "Bearer #{admin_token}"
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
      request.headers["Authorization"] = "Bearer wrong_token"
      get :index
      expect(response).to have_http_status(:unauthorized)
      expect(parsed_body["error"]).to eq("Invalid admin token")
    end

    it "rejects requests with non-Bearer auth scheme" do
      request.headers["Authorization"] = "Basic #{admin_token}"
      get :index
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 503 when ENV token is not configured" do
      ENV.delete("HACKR_ADMIN_API_TOKEN")
      request.headers["Authorization"] = "Bearer #{admin_token}"
      get :index
      expect(response).to have_http_status(:service_unavailable)
      expect(parsed_body["error"]).to include("not configured")
    end
  end

  describe "rate limiting" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      request.headers["Authorization"] = "Bearer #{admin_token}"
      allow(Rails).to receive(:cache).and_return(memory_store)
    end

    it "sets rate limit headers on response" do
      get :index
      expect(response.headers["X-RateLimit-Limit"]).to eq("125")
      expect(response.headers["X-RateLimit-Remaining"]).to be_present
      expect(response.headers["X-RateLimit-Reset"]).to be_present
    end

    it "returns 429 when rate limit is exceeded" do
      window_key = "admin_api_rate:#{Time.current.strftime("%Y%m%d%H%M")}"
      memory_store.write(window_key, 125, expires_in: 2.minutes)

      get :index
      expect(response).to have_http_status(:too_many_requests)
      expect(parsed_body["error"]).to include("Rate limit exceeded")
    end
  end

  describe "#resolve_hackr!" do
    controller(Api::Admin::BaseController) do
      before_action :resolve_hackr!

      def index
        render json: {success: true, hackr_alias: @acting_hackr.hackr_alias}
      end
    end

    before do
      routes.draw { get "index" => "api/admin/base#index" }
      request.headers["Authorization"] = "Bearer #{admin_token}"
    end

    it "resolves a valid hackr by alias" do
      hackr = create(:grid_hackr)
      get :index, params: {hackr_alias: hackr.hackr_alias}
      expect(response).to have_http_status(:ok)
      expect(parsed_body["hackr_alias"]).to eq(hackr.hackr_alias)
    end

    it "returns 404 for unknown hackr alias" do
      get :index, params: {hackr_alias: "nonexistent_hackr"}
      expect(response).to have_http_status(:not_found)
      expect(parsed_body["error"]).to include("not found")
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
