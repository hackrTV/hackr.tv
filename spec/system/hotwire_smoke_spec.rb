require "rails_helper"

# Phase 0 exit criterion: the hotwire layout renders (ERB nav, Stimulus,
# Turbo Drive) and navigation between Hotwire pages is a Turbo visit, not a
# full page load.
RSpec.describe "Hotwire smoke", type: :system do
  it "renders the hotwire layout with the ERB nav" do
    visit "/dev/hotwire/smoke"

    expect(page).to have_content("[ HOTWIRE SMOKE ]")
    expect(page).to have_css("nav.tui-nav.nav-desktop")
    expect(page).to have_css("#player-bar[data-turbo-permanent]", visible: :all)
    expect(page).to have_css("#toast-region", visible: :all)
  end

  it "navigates between Hotwire pages via Turbo Drive (no full reload)" do
    visit "/dev/hotwire/smoke"
    page.execute_script("window.__turbo_marker = true")

    click_link "player spike →"

    expect(page).to have_content("PLAYER SPIKE — PAGE A")
    # A full page load would wipe window state; a Turbo visit keeps it.
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true)
  end

  it "opens and closes a desktop nav dropdown" do
    visit "/dev/hotwire/smoke"

    expect(page).to have_css(".header-dropdown-content", visible: :hidden, minimum: 1)
    find("li.header-dropdown", text: "hackr.tv").click
    expect(page).to have_css(".header-dropdown-content.open", visible: :visible)
    page.find("body").click(x: 10, y: 400)
    expect(page).to have_no_css(".header-dropdown-content.open")
  end
end
