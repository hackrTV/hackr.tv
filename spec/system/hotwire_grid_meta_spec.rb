require "rails_helper"

# Phase 6e: grid meta pages + the terminal easter egg + the
# mission-completed live refresh (the SPA's grid:mission_completed
# CustomEvent, re-pointed through the toast partial).
RSpec.describe "Hotwire grid meta", type: :system do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone, name: "Relay Nexus") }
  let!(:hackr) do
    h = create(:grid_hackr, hackr_alias: "MetaRunner", password: "hackthegrid",
      current_room: room, stats: {"tutorial_completed" => true})
    create(:feature_grant, grid_hackr: h, feature: FeatureGrant::PULSE_GRID)
    h
  end

  def log_in!
    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  it "browses achievements with the category filter" do
    log_in!
    visit "/achievements"

    expect(page).to have_content("ACHIEVEMENTS")
    expect(page).to have_content("Earned:")
  end

  it "switches mission tabs client-side" do
    log_in!
    visit "/missions"

    expect(page).to have_content("No active missions")
    click_button "AVAILABLE (0)"
    expect(page).to have_content("No available missions here.")
    click_button "COMPLETED (0)"
    expect(page).to have_content("No completed missions yet.")
  end

  it "reloads the missions frame on the mission-completed signal" do
    log_in!
    visit "/missions"
    expect(page).to have_content("ACTIVE (0)")

    # A mission completes elsewhere (e.g. terminal turn-in) —
    # simulate the toast's signal after seeding the completed record.
    mission = create(:grid_mission, name: "Ghost Protocol Run")
    create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission,
      status: "completed", completed_at: Time.current)
    page.execute_script("window.dispatchEvent(new CustomEvent('grid:mission_completed'))")

    expect(page).to have_content("COMPLETED (1)", wait: 10)
  end

  it "opens the terminal easter egg with Ctrl+` and closes with ESC" do
    log_in!
    visit "/achievements"

    page.send_keys [:control, "`"]
    expect(page).to have_css(".terminal-egg--open", wait: 5)
    expect(page.find(".terminal-egg-frame", visible: :all)["src"]).to include("/terminal")

    page.send_keys :escape
    expect(page).to have_css(".terminal-egg[hidden]", visible: :all, wait: 5)
  end

  it "opens the terminal easter egg by typing /terminal" do
    log_in!
    visit "/achievements"
    page.execute_script("document.activeElement.blur()")

    page.send_keys "/terminal"
    expect(page).to have_css(".terminal-egg--open", wait: 5)
  end
end
