require "rails_helper"

RSpec.describe "Api::Admin::HackrLogs", type: :request do
  before { ENV["HACKR_ADMIN_API_TOKEN"] = admin_token }
  after { ENV.delete("HACKR_ADMIN_API_TOKEN") }

  describe "GET /api/admin/hackr_logs" do
    it "returns all logs including unpublished" do
      create(:hackr_log, :published)
      create(:hackr_log) # unpublished

      get "/api/admin/hackr_logs", headers: admin_headers
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(body["hackr_logs"].length).to eq(2)
    end

    it "paginates results" do
      create_list(:hackr_log, 3, :published)

      get "/api/admin/hackr_logs", params: {page: 1, per_page: 2}, headers: admin_headers
      body = JSON.parse(response.body)

      expect(body["hackr_logs"].length).to eq(2)
      expect(body["meta"]["total"]).to eq(3)
    end
  end

  describe "POST /api/admin/hackr_logs" do
    let(:hackr) { create(:grid_hackr) }

    it "creates a hackr log" do
      post "/api/admin/hackr_logs",
        params: {hackr_alias: hackr.hackr_alias, title: "New Entry", body: "Content here"},
        headers: admin_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["hackr_log"]["title"]).to eq("New Entry")
      expect(body["hackr_log"]["slug"]).to eq("new-entry")
    end

    it "auto-generates unique slugs" do
      create(:hackr_log, slug: "new-entry", grid_hackr: hackr)

      post "/api/admin/hackr_logs",
        params: {hackr_alias: hackr.hackr_alias, title: "New Entry", body: "Content"},
        headers: admin_headers

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["slug"]).to eq("new-entry-1")
    end

    it "returns 404 for unknown hackr" do
      post "/api/admin/hackr_logs",
        params: {hackr_alias: "nonexistent_hackr", title: "Test", body: "Content"},
        headers: admin_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/admin/hackr_logs/:slug" do
    let!(:log) { create(:hackr_log, title: "Original", body: "Original body") }

    it "updates the log" do
      patch "/api/admin/hackr_logs/#{log.slug}",
        params: {title: "Updated"},
        headers: admin_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["hackr_log"]["title"]).to eq("Updated")
    end

    it "publishes an unpublished log" do
      patch "/api/admin/hackr_logs/#{log.slug}",
        params: {published: true},
        headers: admin_headers

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["published"]).to be true
    end

    it "unpublishes a published log" do
      log.publish!

      patch "/api/admin/hackr_logs/#{log.slug}",
        params: {published: false},
        headers: admin_headers

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["published"]).to be false
    end

    it "returns 404 for unknown slug" do
      patch "/api/admin/hackr_logs/nonexistent",
        params: {title: "Test"},
        headers: admin_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
