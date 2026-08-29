require "rails_helper"

# Server-rendered Handbook pages (Hotwire migration Phase 1). Login-gated.
RSpec.describe "Handbook pages", type: :request do
  let(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  def log_in
    post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  let!(:section) { create(:handbook_section, name: "Getting Started", icon: ">>") }
  let!(:article_one) do
    create(:handbook_article, handbook_section: section,
      title: "First Steps", slug: "first-steps", kind: "tutorial", position: 1,
      summary: "Begin here", body: "Welcome to **THE PULSE GRID**.")
  end
  let!(:article_two) do
    create(:handbook_article, handbook_section: section,
      title: "Next Steps", slug: "next-steps", kind: "reference", position: 2)
  end

  it "redirects anonymous visitors to the grid login" do
    get "/handbook"
    expect(response).to redirect_to("/grid/login")

    get "/handbook/first-steps"
    expect(response).to redirect_to("/grid/login")
  end

  it "renders the index with TOC, sidebar tree, and recent articles" do
    log_in
    get "/handbook"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Operator&#39;s Field Manual").or include("Operator's Field Manual")
    expect(response.body).to include(":: RECENTLY UPDATED ::")
    expect(response.body).to include("Getting Started")
    expect(response.body).to include("First Steps")
    expect(response.body).to include("1 sections · 2 articles")
  end

  it "renders an article with markdown, badges, and prev/next nav" do
    log_in
    get "/handbook/next-steps"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Next Steps")
    expect(response.body).to include("← PREVIOUS")
    expect(response.body).to include("First Steps")

    get "/handbook/first-steps"
    expect(response.body).to include("<strong>THE PULSE GRID</strong>")
    expect(response.body).to include("NEXT →")
    expect(response.body).to include("tutorial")
  end

  it "404s for articles in unpublished sections" do
    hidden_section = create(:handbook_section, :unpublished, name: "Hidden")
    hidden = create(:handbook_article, handbook_section: hidden_section, slug: "ghost-article")

    log_in
    get "/handbook/#{hidden.slug}"
    expect(response).to have_http_status(:not_found)
  end
end
