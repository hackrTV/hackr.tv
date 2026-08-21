require "rails_helper"

# Phase 1: server-rendered Codex with client-side type filter + search.
RSpec.describe "Hotwire codex pages", type: :system do
  let!(:person) do
    create(:codex_entry, :published, name: "XERAEN", slug: "xeraen",
      entry_type: "person", summary: "Legendary hackr",
      content: "Broadcasts beside [[The Fracture Network]].")
  end
  let!(:faction) do
    create(:codex_entry, :published, name: "The Fracture Network", slug: "the-fracture-network",
      entry_type: "faction", summary: "The resistance", content: "Fights on.")
  end

  before { Rails.cache.delete(CodexLinker::MAPPINGS_CACHE_KEY) }

  it "filters by type and search, and follows wiki links between entries" do
    visit "/codex"
    page.execute_script("window.__turbo_marker = true")

    expect(page).to have_content("Showing 2 of 2 entries")

    # Type filter
    click_button(text: /Faction/)
    expect(page).to have_content("Showing 1 of 2 entries")
    expect(page).to have_no_content("Legendary hackr")
    expect(page).to have_content("The resistance")

    # Back to all + search
    click_button(text: /^All/)
    fill_in "codex-search", with: "legendary"
    expect(page).to have_content("Showing 1 of 2 entries")
    expect(page).to have_content("Legendary hackr")

    # Search that matches nothing shows the empty state
    fill_in "codex-search", with: "zzzz"
    expect(page).to have_content("No entries found matching your criteria.")

    # Clear and open the entry (scope to the grid — the nav also contains
    # "XERAEN" via the XERAEN.net artist link)
    fill_in "codex-search", with: ""
    page.execute_script("document.getElementById('codex-search').dispatchEvent(new Event('input', {bubbles: true}))")
    expect(page).to have_content("Showing 2 of 2 entries")
    within(".codex-grid") { click_link(text: /XERAEN/) }
    expect(page).to have_css(".codex-entry-name", text: "XERAEN")

    # Wiki link resolved server-side → navigates to the other entry (Turbo)
    within(".codex-content") { click_link "The Fracture Network" }
    expect(page).to have_css(".codex-entry-name", text: "The Fracture Network")
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true)
  end
end
