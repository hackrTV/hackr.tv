require "rails_helper"

RSpec.describe "Api::Admin::Pulses", type: :request do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }
  let(:valid_headers) { admin_headers_for(admin_hackr, raw_token) }

  describe "POST /api/admin/pulses" do
    it "creates a pulse as the authenticated admin" do
      post "/api/admin/pulses",
        params: {content: "Admin pulse"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["pulse"]["content"]).to eq("Admin pulse")
      expect(body["pulse"]["grid_hackr"]["hackr_alias"]).to eq(admin_hackr.hackr_alias)
    end

    it "enforces 256 character limit" do
      post "/api/admin/pulses",
        params: {content: "x" * 257},
        headers: valid_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "applies profanity filter" do
      allow(Obscenity).to receive(:profane?).and_call_original
      allow(Obscenity).to receive(:profane?).with("bad content").and_return(true)

      post "/api/admin/pulses",
        params: {content: "bad content"},
        headers: valid_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/admin/pulses/:pulse_id/echo" do
    let(:pulse) { create(:pulse) }

    it "creates an echo" do
      post "/api/admin/pulses/#{pulse.id}/echo",
        headers: valid_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["echoed"]).to be true
    end

    it "toggles echo off when already echoed" do
      create(:echo, pulse: pulse, grid_hackr: admin_hackr)

      post "/api/admin/pulses/#{pulse.id}/echo",
        headers: valid_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["echoed"]).to be false
    end

    it "returns 404 for unknown pulse" do
      post "/api/admin/pulses/99999/echo",
        headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/admin/pulses/splice" do
    let(:parent) { create(:pulse) }

    it "creates a splice to a parent pulse" do
      post "/api/admin/pulses/splice",
        params: {parent_pulse_id: parent.id, content: "Reply"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["pulse"]["parent_pulse_id"]).to eq(parent.id)
      expect(body["pulse"]["thread_root_id"]).to eq(parent.id)
    end

    it "rejects splice to signal-dropped pulse" do
      parent.signal_drop!

      post "/api/admin/pulses/splice",
        params: {parent_pulse_id: parent.id, content: "Reply"},
        headers: valid_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for unknown parent pulse" do
      post "/api/admin/pulses/splice",
        params: {parent_pulse_id: 99999, content: "Reply"},
        headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
