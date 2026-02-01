require "rails_helper"

RSpec.describe Api::Admin::PulsesController, type: :controller do
  before do
    ENV["HACKR_ADMIN_API_TOKEN"] = admin_token
    request.headers["Authorization"] = "Bearer #{admin_token}"
  end

  after { ENV.delete("HACKR_ADMIN_API_TOKEN") }

  let(:hackr) { create(:grid_hackr) }

  describe "POST #create" do
    it "creates a pulse on behalf of the hackr" do
      post :create, params: {hackr_alias: hackr.hackr_alias, content: "Test pulse"}

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["pulse"]["content"]).to eq("Test pulse")
      expect(body["pulse"]["grid_hackr"]["hackr_alias"]).to eq(hackr.hackr_alias)
    end

    it "enforces 256 character limit" do
      post :create, params: {hackr_alias: hackr.hackr_alias, content: "x" * 257}

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "applies profanity filter" do
      # Profanity filter is on the model level via ProfanityFilterable
      # Mock only for the specific content to avoid affecting factory
      allow(Obscenity).to receive(:profane?).and_call_original
      allow(Obscenity).to receive(:profane?).with("filtered content").and_return(true)

      post :create, params: {hackr_alias: hackr.hackr_alias, content: "filtered content"}

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("GOVCORP CENSOR")
    end

    it "returns 404 for unknown hackr" do
      post :create, params: {hackr_alias: "nonexistent_hackr", content: "Test"}

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #echo" do
    let(:pulse) { create(:pulse) }

    it "creates an echo for the hackr" do
      post :echo, params: {hackr_alias: hackr.hackr_alias, pulse_id: pulse.id}

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["echoed"]).to be true
      expect(body["echo_count"]).to eq(1)
    end

    it "removes an existing echo (toggle)" do
      create(:echo, pulse: pulse, grid_hackr: hackr)

      post :echo, params: {hackr_alias: hackr.hackr_alias, pulse_id: pulse.id}

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["echoed"]).to be false
    end

    it "returns 404 for unknown pulse" do
      post :echo, params: {hackr_alias: hackr.hackr_alias, pulse_id: 99999}

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for unknown hackr" do
      post :echo, params: {hackr_alias: "nonexistent_hackr", pulse_id: pulse.id}

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #splice" do
    let(:parent_pulse) { create(:pulse) }

    it "creates a splice (reply) to a parent pulse" do
      post :splice, params: {
        hackr_alias: hackr.hackr_alias,
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
        hackr_alias: hackr.hackr_alias,
        parent_pulse_id: 99999,
        content: "Reply"
      }

      expect(response).to have_http_status(:not_found)
    end

    it "rejects splice to a signal-dropped pulse" do
      parent_pulse.signal_drop!

      post :splice, params: {
        hackr_alias: hackr.hackr_alias,
        parent_pulse_id: parent_pulse.id,
        content: "Reply"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to include("signal-dropped")
    end
  end
end
