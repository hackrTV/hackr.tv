require "rails_helper"

RSpec.describe Api::Admin::HackrLogsController, type: :controller do
  before do
    ENV["HACKR_ADMIN_API_TOKEN"] = admin_token
    request.headers["Authorization"] = "Bearer #{admin_token}"
  end

  after { ENV.delete("HACKR_ADMIN_API_TOKEN") }

  describe "GET #index" do
    it "returns all logs including unpublished" do
      create(:hackr_log, :published)
      create(:hackr_log) # unpublished

      get :index
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(body["hackr_logs"].length).to eq(2)
    end

    it "paginates results" do
      create_list(:hackr_log, 3, :published)

      get :index, params: {page: 1, per_page: 2}
      body = JSON.parse(response.body)

      expect(body["hackr_logs"].length).to eq(2)
      expect(body["meta"]["total"]).to eq(3)
      expect(body["meta"]["total_pages"]).to eq(2)
    end

    it "includes hackr info" do
      log = create(:hackr_log, :published)

      get :index
      body = JSON.parse(response.body)

      entry = body["hackr_logs"].first
      expect(entry["grid_hackr"]["hackr_alias"]).to eq(log.grid_hackr.hackr_alias)
    end
  end

  describe "POST #create" do
    let(:hackr) { create(:grid_hackr) }

    it "creates a hackr log with auto-generated slug" do
      post :create, params: {
        hackr_alias: hackr.hackr_alias,
        title: "Resistance Update Alpha",
        body: "The fight continues"
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["hackr_log"]["slug"]).to eq("resistance-update-alpha")
      expect(body["hackr_log"]["published"]).to be true
    end

    it "handles slug collisions" do
      create(:hackr_log, slug: "test-title", grid_hackr: hackr)

      post :create, params: {
        hackr_alias: hackr.hackr_alias,
        title: "Test Title",
        body: "Content"
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["hackr_log"]["slug"]).to eq("test-title-1")
    end

    it "defaults published to true and sets published_at" do
      post :create, params: {
        hackr_alias: hackr.hackr_alias,
        title: "New Log",
        body: "Content"
      }

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["published"]).to be true
      expect(body["hackr_log"]["published_at"]).to be_present
    end

    it "allows creating unpublished log" do
      post :create, params: {
        hackr_alias: hackr.hackr_alias,
        title: "Draft Log",
        body: "Content",
        published: false
      }

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["published"]).to be false
      expect(body["hackr_log"]["published_at"]).to be_nil
    end

    it "returns 404 for unknown hackr" do
      post :create, params: {
        hackr_alias: "nonexistent_hackr",
        title: "Test",
        body: "Content"
      }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 for invalid data" do
      post :create, params: {
        hackr_alias: hackr.hackr_alias,
        title: "",
        body: ""
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH #update" do
    let!(:log) { create(:hackr_log, title: "Original", body: "Original body") }

    it "updates only provided fields" do
      patch :update, params: {slug: log.slug, title: "Updated Title"}

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["hackr_log"]["title"]).to eq("Updated Title")
      expect(body["hackr_log"]["body"]).to eq("Original body")
    end

    it "publishes an unpublished log" do
      patch :update, params: {slug: log.slug, published: true}

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["published"]).to be true
      expect(body["hackr_log"]["published_at"]).to be_present
    end

    it "unpublishes a published log" do
      log.publish!

      patch :update, params: {slug: log.slug, published: false}

      body = JSON.parse(response.body)
      expect(body["hackr_log"]["published"]).to be false
    end

    it "returns 404 for unknown slug" do
      patch :update, params: {slug: "nonexistent"}
      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 for invalid update" do
      patch :update, params: {slug: log.slug, title: ""}

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
