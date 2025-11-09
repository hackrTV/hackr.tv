require "rails_helper"

RSpec.describe HackrLogsController, type: :request do
  let(:author) { create(:grid_hackr, :admin) }

  describe "GET /logs" do
    it "returns http success" do
      get "/logs"
      expect(response).to have_http_status(:success)
    end

    it "displays published logs" do
      create(:hackr_log, :published, author: author, title: "Public Transmission")
      get "/logs"
      expect(response.body).to include("Public Transmission")
    end

    it "does not display unpublished logs" do
      create(:hackr_log, author: author, title: "Draft Transmission", published: false)
      get "/logs"
      expect(response.body).not_to include("Draft Transmission")
    end

    it "orders logs by published_at descending" do
      create(:hackr_log, :published, author: author, title: "Old Log", published_at: 2.days.ago)
      create(:hackr_log, :published, author: author, title: "New Log", published_at: 1.day.ago)

      get "/logs"
      # New log should appear before old log
      expect(response.body.index("New Log")).to be < response.body.index("Old Log")
    end

    it "displays empty state when no published logs" do
      create(:hackr_log, author: author, published: false)
      get "/logs"
      expect(response.body).to include("No transmissions available yet")
    end
  end

  describe "GET /logs/:id" do
    let(:log) { create(:hackr_log, :published, author: author, slug: "test-log", title: "Test Log") }

    it "returns http success" do
      get "/logs/#{log.slug}"
      expect(response).to have_http_status(:success)
    end

    it "displays the log title" do
      get "/logs/#{log.slug}"
      expect(response.body).to include("Test Log")
    end

    it "displays the log body" do
      log.update!(body: "This is the log content")
      get "/logs/#{log.slug}"
      expect(response.body).to include("This is the log content")
    end

    it "displays author information" do
      get "/logs/#{log.slug}"
      expect(response.body).to include(author.hackr_alias)
    end

    it "redirects when log is not published" do
      unpublished = create(:hackr_log, author: author, slug: "unpublished", published: false)
      get "/logs/#{unpublished.slug}"
      expect(response).to redirect_to(hackr_logs_path)
    end

    it "redirects when log is not found" do
      get "/logs/nonexistent-slug"
      expect(response).to redirect_to(hackr_logs_path)
    end

    context "when logged in as admin" do
      before do
        post "/grid/login", params: {hackr_alias: author.hackr_alias, password: "password123"}
      end

      it "shows edit button" do
        get "/logs/#{log.slug}"
        expect(response.body).to include("Edit This Log")
      end
    end

    context "when not logged in" do
      it "does not show edit button" do
        get "/logs/#{log.slug}"
        expect(response.body).not_to include("Edit This Log")
      end
    end
  end
end
