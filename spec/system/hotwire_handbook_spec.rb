require "rails_helper"

# Phase 1: handbook behind login. The spec logs in through the React SPA
# login page — which doubles as a cross-stack proof: session established on
# an SPA page carries into Hotwire pages.
RSpec.describe "Hotwire handbook pages", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }
  let!(:section) { create(:handbook_section, name: "Getting Started") }
  let!(:article) do
    create(:handbook_article, handbook_section: section,
      title: "First Steps", slug: "first-steps", kind: "tutorial",
      summary: "Begin here", body: "Welcome, operator.")
  end
  let!(:other) do
    create(:handbook_article, handbook_section: section,
      title: "Deck Basics", slug: "deck-basics", kind: "reference")
  end

  it "logs in via the SPA, browses the handbook, and filters the sidebar" do
    visit "/handbook"
    # Anonymous → redirected to the React login page
    expect(page).to have_field("hackr_alias")

    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"

    # Back on a logged-in SPA page; go to the handbook (full load — plain anchor)
    visit "/handbook"
    expect(page).to have_content("Operator's Field Manual")
    expect(page).to have_content("Getting Started")

    # Sidebar search filters articles
    fill_in placeholder: "Search articles...", with: "deck"
    expect(page).to have_no_css(".hb-article-link", text: "First Steps", visible: :visible)
    expect(page).to have_css(".hb-article-link", text: "Deck Basics", visible: :visible)

    # Open an article via the sidebar (Turbo) — scoped: the TOC also links it
    page.execute_script("window.__turbo_marker = true")
    within(".hb-sidebar") { click_link "Deck Basics" }
    expect(page).to have_css(".hb-article-title", text: "Deck Basics")
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true)

    # Prev/next nav between siblings
    within(".hb-prevnext") { click_link(text: /First Steps/) }
    expect(page).to have_css(".hb-article-title", text: "First Steps")
    expect(page).to have_content("Welcome, operator.")
  end
end
