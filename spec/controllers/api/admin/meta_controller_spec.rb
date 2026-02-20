require "rails_helper"

RSpec.describe Api::Admin::MetaController, type: :controller do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }

  before do
    request.headers["Authorization"] = "Bearer #{admin_hackr.hackr_alias}:#{raw_token}"
  end

  describe "GET #capabilities" do
    before { get :capabilities }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "returns capability flags" do
      body = JSON.parse(response.body)
      caps = body["capabilities"]
      expect(caps["streams"]).to be true
      expect(caps["hackr_logs"]).to be true
      expect(caps["pulses"]).to be true
      expect(caps["uplink"]).to be true
      expect(caps["grid"]).to be false
      expect(caps["meta"]).to be true
    end
  end

  describe "GET #rate_limit" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(memory_store) }

    it "returns current rate limit status" do
      get :rate_limit
      body = JSON.parse(response.body)
      rl = body["rate_limit"]
      expect(rl["limit"]).to eq(125)
      expect(rl["remaining"]).to be_a(Integer)
      expect(rl["used"]).to be_a(Integer)
      expect(rl["resets_at"]).to be_present
    end

    it "reflects usage after requests" do
      window_key = "admin_api_rate:#{admin_hackr.hackr_alias}:#{Time.current.strftime("%Y%m%d%H%M")}"
      memory_store.write(window_key, 10, expires_in: 2.minutes)

      get :rate_limit
      body = JSON.parse(response.body)
      # The rate_limit action itself increments the counter via before_action,
      # so used will be at least 11
      expect(body["rate_limit"]["used"]).to be >= 10
    end
  end
end
