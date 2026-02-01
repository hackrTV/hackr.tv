require "rails_helper"

RSpec.describe "Api::Admin::Pulses", type: :request do
  before { ENV["HACKR_ADMIN_API_TOKEN"] = admin_token }
  after { ENV.delete("HACKR_ADMIN_API_TOKEN") }

  let(:hackr) { create(:grid_hackr) }

  describe "POST /api/admin/pulses" do
    it "creates a pulse on behalf of a hackr" do
      post "/api/admin/pulses",
        params: {hackr_alias: hackr.hackr_alias, content: "Admin pulse"},
        headers: admin_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["pulse"]["content"]).to eq("Admin pulse")
      expect(body["pulse"]["grid_hackr"]["hackr_alias"]).to eq(hackr.hackr_alias)
    end

    it "enforces 256 character limit" do
      post "/api/admin/pulses",
        params: {hackr_alias: hackr.hackr_alias, content: "x" * 257},
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "applies profanity filter" do
      allow(Obscenity).to receive(:profane?).and_call_original
      allow(Obscenity).to receive(:profane?).with("bad content").and_return(true)

      post "/api/admin/pulses",
        params: {hackr_alias: hackr.hackr_alias, content: "bad content"},
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for unknown hackr" do
      post "/api/admin/pulses",
        params: {hackr_alias: "nonexistent_hackr", content: "Test"},
        headers: admin_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/admin/pulses/:pulse_id/echo" do
    let(:pulse) { create(:pulse) }

    it "creates an echo" do
      post "/api/admin/pulses/#{pulse.id}/echo",
        params: {hackr_alias: hackr.hackr_alias},
        headers: admin_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["echoed"]).to be true
    end

    it "toggles echo off when already echoed" do
      create(:echo, pulse: pulse, grid_hackr: hackr)

      post "/api/admin/pulses/#{pulse.id}/echo",
        params: {hackr_alias: hackr.hackr_alias},
        headers: admin_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["echoed"]).to be false
    end

    it "returns 404 for unknown pulse" do
      post "/api/admin/pulses/99999/echo",
        params: {hackr_alias: hackr.hackr_alias},
        headers: admin_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/admin/pulses/splice" do
    let(:parent) { create(:pulse) }

    it "creates a splice to a parent pulse" do
      post "/api/admin/pulses/splice",
        params: {hackr_alias: hackr.hackr_alias, parent_pulse_id: parent.id, content: "Reply"},
        headers: admin_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["pulse"]["parent_pulse_id"]).to eq(parent.id)
      expect(body["pulse"]["thread_root_id"]).to eq(parent.id)
    end

    it "rejects splice to signal-dropped pulse" do
      parent.signal_drop!

      post "/api/admin/pulses/splice",
        params: {hackr_alias: hackr.hackr_alias, parent_pulse_id: parent.id, content: "Reply"},
        headers: admin_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for unknown parent pulse" do
      post "/api/admin/pulses/splice",
        params: {hackr_alias: hackr.hackr_alias, parent_pulse_id: 99999, content: "Reply"},
        headers: admin_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
