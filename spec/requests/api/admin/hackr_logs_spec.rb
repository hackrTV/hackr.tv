require "rails_helper"

RSpec.describe "Api::Admin::HackrLogs", type: :request do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }
  let(:valid_headers) { admin_headers_for(admin_hackr, raw_token) }

  describe "GET /api/admin/hackr_logs" do
    it "returns all logs including unpublished" do
      create(:hackr_log, :published)
      create(:hackr_log) # unpublished

      get "/api/admin/hackr_logs", headers: valid_headers
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(body["hackr_logs"].length).to eq(2)
    end

    it "paginates results" do
      create_list(:hackr_log, 3, :published)

      get "/api/admin/hackr_logs", params: {page: 1, per_page: 2}, headers: valid_headers
      body = JSON.parse(response.body)

      expect(body["hackr_logs"].length).to eq(2)
      expect(body["meta"]["total"]).to eq(3)
    end
  end

  describe "POST /api/admin/hackr_logs" do
    it "creates a hackr log as the authenticated admin" do
      post "/api/admin/hackr_logs",
        params: {title: "New Entry", body: "Content here"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["hackr_log"]["title"]).to eq("New Entry")
      expect(body["hackr_log"]["slug"]).to eq("new-entry")
      expect(body["hackr_log"]["grid_hackr"]["hackr_alias"]).to eq(admin_hackr.hackr_alias)
    end

    it "auto-generates unique slugs" do
      create(:hackr_log, slug: "new-entry", grid_hackr: admin_hackr)

      post "/api/admin/hackr_logs",
        params: {title: "New Entry", body: "Content"},
        headers: valid_headers

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["slug"]).to eq("new-entry-1")
    end
  end

  describe "PATCH /api/admin/hackr_logs/:slug" do
    let!(:log) { create(:hackr_log, title: "Original", body: "Original body") }

    it "updates the log" do
      patch "/api/admin/hackr_logs/#{log.slug}",
        params: {title: "Updated"},
        headers: valid_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["hackr_log"]["title"]).to eq("Updated")
    end

    it "publishes an unpublished log" do
      patch "/api/admin/hackr_logs/#{log.slug}",
        params: {published: true},
        headers: valid_headers

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["published"]).to be true
    end

    it "unpublishes a published log" do
      log.publish!

      patch "/api/admin/hackr_logs/#{log.slug}",
        params: {published: false},
        headers: valid_headers

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["published"]).to be false
    end

    it "returns 404 for unknown slug" do
      patch "/api/admin/hackr_logs/nonexistent",
        params: {title: "Test"},
        headers: valid_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
