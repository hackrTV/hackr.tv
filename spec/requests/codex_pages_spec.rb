require "rails_helper"

# Server-rendered Codex pages (Hotwire migration Phase 1).
RSpec.describe "Codex pages", type: :request do
  describe "GET /codex" do
    it "renders all published entries with filter data attributes" do
      entry = create(:codex_entry, :published, name: "XERAEN", slug: "xeraen",
        entry_type: "person", summary: "Legendary hackr",
        metadata: {"role" => "Broadcaster", "search_tags" => ["signal"]})
      create(:codex_entry, name: "Hidden Draft", slug: "hidden-draft")

      get "/codex"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("THE CODEX :: Knowledge Archive")
      expect(response.body).to include("XERAEN")
      expect(response.body).to include("Legendary hackr")
      expect(response.body).not_to include("Hidden Draft")
      # Search haystack includes metadata + search_tags, downcased
      expect(response.body).to include('data-entry-type="person"')
      expect(response.body).to match(/data-search="[^"]*signal[^"]*"/)
      expect(response.body).to include("role: Broadcaster")
      expect(response.body).to include(entry.slug)
    end
  end

  describe "GET /codex/:slug" do
    it "renders entry content with markdown, metadata, and wiki links" do
      create(:codex_entry, :published, name: "The Pulse Grid", slug: "the-pulse-grid")
      Rails.cache.delete(CodexLinker::MAPPINGS_CACHE_KEY)
      create(:codex_entry, :published, name: "GovCorp", slug: "govcorp",
        entry_type: "organization",
        summary: "The enemy.",
        metadata: {"founded" => "2089", "search_tags" => ["gc"]},
        content: "**Controls** [[the-pulse-grid]].")

      get "/codex/govcorp"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("GovCorp")
      expect(response.body).to include("The enemy.")
      expect(response.body).to include("founded")
      expect(response.body).not_to include("search_tags")
      expect(response.body).to include("<strong>Controls</strong>")
      expect(response.body).to include('href="/codex/the-pulse-grid"')
      expect(response.body).to include("The Pulse Grid")
    end

    it "404s for unpublished or unknown entries" do
      draft = create(:codex_entry, name: "Draft", slug: "draft-entry")

      get "/codex/#{draft.slug}"
      expect(response).to have_http_status(:not_found)

      get "/codex/never-existed"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Codex entry not found")
    end

    it "records a read for the logged-in hackr" do
      hackr = create(:grid_hackr, password: "hackthegrid")
      entry = create(:codex_entry, :published)

      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}

      expect {
        get "/codex/#{entry.slug}"
      }.to change { CodexEntryRead.where(grid_hackr: hackr, codex_entry: entry).count }.by(1)
    end
  end
end
