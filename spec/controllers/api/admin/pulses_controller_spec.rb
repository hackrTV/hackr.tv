require "rails_helper"

RSpec.describe Api::Admin::PulsesController, type: :controller do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }

  before do
    request.headers["Authorization"] = "Bearer #{admin_hackr.hackr_alias}:#{raw_token}"
  end

  describe "POST #create" do
    it "creates a pulse as the authenticated admin" do
      post :create, params: {content: "Test pulse"}

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["pulse"]["content"]).to eq("Test pulse")
      expect(body["pulse"]["grid_hackr"]["hackr_alias"]).to eq(admin_hackr.hackr_alias)
    end

    it "enforces 256 character limit" do
      post :create, params: {content: "x" * 257}

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "applies profanity filter" do
      allow(Obscenity).to receive(:profane?).and_call_original
      allow(Obscenity).to receive(:profane?).with("filtered content").and_return(true)

      post :create, params: {content: "filtered content"}

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("GOVCORP CENSOR")
    end
  end

  describe "POST #echo" do
    let(:pulse) { create(:pulse) }

    it "creates an echo for the admin" do
      post :echo, params: {pulse_id: pulse.id}

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["echoed"]).to be true
      expect(body["echo_count"]).to eq(1)
    end

    it "removes an existing echo (toggle)" do
      create(:echo, pulse: pulse, grid_hackr: admin_hackr)

      post :echo, params: {pulse_id: pulse.id}

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["echoed"]).to be false
    end

    it "returns 404 for unknown pulse" do
      post :echo, params: {pulse_id: 99999}

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #splice" do
    let(:parent_pulse) { create(:pulse) }

    it "creates a splice (reply) to a parent pulse" do
      post :splice, params: {
        parent_pulse_id: parent_pulse.id,
        content: "Reply content"
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["pulse"]["parent_pulse_id"]).to eq(parent_pulse.id)
      expect(body["pulse"]["is_splice"]).to be true
      expect(body["pulse"]["thread_root_id"]).to eq(parent_pulse.id)
    end

    it "returns 404 for unknown parent pulse" do
      post :splice, params: {
        parent_pulse_id: 99999,
        content: "Reply"
      }

      expect(response).to have_http_status(:not_found)
    end

    it "rejects splice to a signal-dropped pulse" do
      parent_pulse.signal_drop!

      post :splice, params: {
        parent_pulse_id: parent_pulse.id,
        content: "Reply"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("signal-dropped")
    end
  end
end
