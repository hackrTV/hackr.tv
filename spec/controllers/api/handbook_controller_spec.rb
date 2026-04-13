require "rails_helper"

RSpec.describe Api::HandbookController, type: :controller do
  let(:hackr) { create(:grid_hackr) }

  describe "authentication" do
    it "returns 401 for unauthenticated requests to #index" do
      get :index, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for unauthenticated requests to #show" do
      article = create(:handbook_article)
      get :show, params: {slug: article.slug}, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for unauthenticated requests to #recent" do
      get :recent, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for unauthenticated requests to #mappings" do
      get :mappings, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET #index (authenticated)" do
    before { session[:grid_hackr_id] = hackr.id }

    it "returns the published section tree" do
      section = create(:handbook_section, name: "THE PULSE GRID", position: 0)
      published = create(:handbook_article, handbook_section: section, title: "Clearance", position: 0)
      unpublished = create(:handbook_article, :unpublished, handbook_section: section)
      hidden_section = create(:handbook_section, :unpublished)
      create(:handbook_article, handbook_section: hidden_section)

      get :index, format: :json
      expect(response).to have_http_status(:ok)
      payload = JSON.parse(response.body)

      expect(payload["sections"].length).to eq(1)
      section_payload = payload["sections"].first
      expect(section_payload["slug"]).to eq(section.slug)
      expect(section_payload["articles"].length).to eq(1)
      expect(section_payload["articles"].first["slug"]).to eq(published.slug)
      expect(section_payload["articles"].map { |a| a["slug"] }).not_to include(unpublished.slug)
    end

    it "includes metadata in article summaries so tag search can match" do
      section = create(:handbook_section)
      create(:handbook_article,
        handbook_section: section,
        metadata: {"search_tags" => ["cred", "mining"]})

      get :index, format: :json
      article_payload = JSON.parse(response.body)["sections"].first["articles"].first
      expect(article_payload["metadata"]).to eq("search_tags" => ["cred", "mining"])
    end

    it "orders sections by position then name" do
      later = create(:handbook_section, name: "Zeta", position: 5)
      earlier = create(:handbook_section, name: "Alpha", position: 1)

      get :index, format: :json
      slugs = JSON.parse(response.body)["sections"].map { |s| s["slug"] }
      expect(slugs).to eq([earlier.slug, later.slug])
    end
  end

  describe "GET #show (authenticated)" do
    before { session[:grid_hackr_id] = hackr.id }

    let(:section) { create(:handbook_section) }
    let!(:article_a) { create(:handbook_article, handbook_section: section, title: "A", position: 0) }
    let!(:article_b) { create(:handbook_article, handbook_section: section, title: "B", position: 1) }
    let!(:article_c) { create(:handbook_article, handbook_section: section, title: "C", position: 2) }

    it "returns the article with section context" do
      get :show, params: {slug: article_b.slug}, format: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["slug"]).to eq(article_b.slug)
      expect(body["body"]).to be_present
      expect(body["section"]["slug"]).to eq(section.slug)
    end

    it "includes prev/next siblings within the section" do
      get :show, params: {slug: article_b.slug}, format: :json
      body = JSON.parse(response.body)

      expect(body["prev_article"]["slug"]).to eq(article_a.slug)
      expect(body["next_article"]["slug"]).to eq(article_c.slug)
    end

    it "returns nil prev for the first article" do
      get :show, params: {slug: article_a.slug}, format: :json
      body = JSON.parse(response.body)
      expect(body["prev_article"]).to be_nil
      expect(body["next_article"]["slug"]).to eq(article_b.slug)
    end

    it "returns nil next for the last article" do
      get :show, params: {slug: article_c.slug}, format: :json
      body = JSON.parse(response.body)
      expect(body["prev_article"]["slug"]).to eq(article_b.slug)
      expect(body["next_article"]).to be_nil
    end

    it "returns 404 for unknown slug" do
      get :show, params: {slug: "nope"}, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for unpublished articles" do
      hidden = create(:handbook_article, :unpublished, handbook_section: section)
      get :show, params: {slug: hidden.slug}, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a published article in an unpublished section" do
      hidden_section = create(:handbook_section, :unpublished)
      orphaned = create(:handbook_article, handbook_section: hidden_section)
      get :show, params: {slug: orphaned.slug}, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #recent (authenticated)" do
    before { session[:grid_hackr_id] = hackr.id }

    it "returns the most recently updated published articles" do
      section = create(:handbook_section)
      old = create(:handbook_article, handbook_section: section, title: "Old")
      old.update_column(:updated_at, 2.days.ago)
      recent = create(:handbook_article, handbook_section: section, title: "Recent")

      get :recent, format: :json
      body = JSON.parse(response.body)
      expect(body.first["slug"]).to eq(recent.slug)
      expect(body.map { |a| a["slug"] }).to include(old.slug)
      expect(body.first["section"]["slug"]).to eq(section.slug)
    end

    it "honors the limit param, capped at 20" do
      section = create(:handbook_section)
      create_list(:handbook_article, 3, handbook_section: section)

      get :recent, params: {limit: 2}, format: :json
      body = JSON.parse(response.body)
      expect(body.length).to eq(2)
    end

    it "excludes unpublished articles" do
      section = create(:handbook_section)
      create(:handbook_article, :unpublished, handbook_section: section)

      get :recent, format: :json
      expect(JSON.parse(response.body)).to be_empty
    end

    it "excludes published articles whose section is unpublished" do
      hidden_section = create(:handbook_section, :unpublished)
      create(:handbook_article, handbook_section: hidden_section)

      get :recent, format: :json
      expect(JSON.parse(response.body)).to be_empty
    end
  end

  describe "GET #mappings (authenticated)" do
    before { session[:grid_hackr_id] = hackr.id }

    it "returns a slug->title hash for published articles only" do
      section = create(:handbook_section)
      published = create(:handbook_article, handbook_section: section, slug: "mining", title: "Mining")
      create(:handbook_article, :unpublished, handbook_section: section, slug: "secret", title: "Secret")

      get :mappings, format: :json
      body = JSON.parse(response.body)
      expect(body).to eq({published.slug => published.title})
    end

    it "excludes published articles whose section is unpublished" do
      hidden_section = create(:handbook_section, :unpublished)
      create(:handbook_article, handbook_section: hidden_section, slug: "hidden-article", title: "Hidden")

      get :mappings, format: :json
      expect(JSON.parse(response.body)).to be_empty
    end
  end
end
