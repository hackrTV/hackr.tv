require "rails_helper"

# Server-rendered Hackr Logs pages (Hotwire migration Phase 1).
# The JSON API keeps its own specs; these cover the HTML routes.
RSpec.describe "Logs pages", type: :request do
  describe "GET /logs" do
    it "renders published logs for the default timeline" do
      log = create(:hackr_log, :published, title: "Fracture Dispatch")
      create(:hackr_log, title: "Unpublished Draft")

      get "/logs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("HACKR LOGS")
      expect(response.body).to include("Fracture Dispatch")
      expect(response.body).not_to include("Unpublished Draft")
      expect(response.body).to include(log.grid_hackr.hackr_alias)
    end

    it "filters by timeline and paginates" do
      create(:hackr_log, :published, title: "Now Log", timeline: "2120s")
      create(:hackr_log, :published, title: "Old Log", timeline: "pre_fracture")
      6.times { |i| create(:hackr_log, :published, title: "Filler #{i}", timeline: "govcorp_files") }

      get "/logs", params: {timeline: "pre_fracture"}
      expect(response.body).to include("Old Log")
      expect(response.body).not_to include("Now Log")

      # per_page defaults to 5 (API parity) → 6 govcorp logs paginate
      get "/logs", params: {timeline: "govcorp_files"}
      expect(response.body).to include("Page 1 of 2")
      expect(response.body).to include("Next »")
    end

    it "sorts ascending when requested" do
      create(:hackr_log, :published, title: "Older", published_at: 2.days.ago)
      create(:hackr_log, :published, title: "Newer", published_at: 1.hour.ago)

      get "/logs", params: {sort: "asc"}

      expect(response.body.index("Older")).to be < response.body.index("Newer")
    end
  end

  describe "GET /logs/:slug" do
    it "renders the log with markdown body and resolved codex links" do
      create(:codex_entry, :published, name: "The Pulse Grid", slug: "the-pulse-grid")
      Rails.cache.delete(CodexLinker::MAPPINGS_CACHE_KEY)
      log = create(:hackr_log, :published,
        body: "**Bold intel** about [[the-pulse-grid]].")

      get "/logs/#{log.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<strong>Bold intel</strong>")
      expect(response.body).to include('href="/codex/the-pulse-grid"')
      expect(response.body).to include("The Pulse Grid")
    end

    it "404s for unpublished or unknown slugs" do
      draft = create(:hackr_log, published: false)

      get "/logs/#{draft.slug}"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Log not found or not yet published.")

      get "/logs/nope-nothing"
      expect(response).to have_http_status(:not_found)
    end

    it "records a read for the logged-in hackr" do
      hackr = create(:grid_hackr, password: "hackthegrid")
      log = create(:hackr_log, :published)

      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
      expect(response).to have_http_status(:ok)

      expect {
        get "/logs/#{log.slug}"
      }.to change { HackrLogRead.where(grid_hackr: hackr, hackr_log: log).count }.by(1)
      expect(response).to have_http_status(:ok)
    end

    it "does not record reads for anonymous visitors" do
      log = create(:hackr_log, :published)
      expect { get "/logs/#{log.slug}" }.not_to change(HackrLogRead, :count)
    end
  end
end
