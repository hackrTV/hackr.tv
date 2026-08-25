require "rails_helper"

# Phase 3: wire profiles — inline bio frame, pins, timeline indicators.
RSpec.describe "Hotwire wire profile", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid", bio: "Ghost in the wire") }
  let!(:other) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(as = hackr)
    visit "/grid/login"
    fill_in "hackr_alias", with: as.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  it "renders header, stats, and indicators" do
    create(:pulse, grid_hackr: hackr, content: "My own broadcast")
    echoed = create(:pulse, grid_hackr: other, content: "Someone else's signal")
    Echo.create!(pulse: echoed, grid_hackr: hackr)

    visit "/wire/#{hackr.hackr_alias.downcase}"

    expect(page).to have_content("@#{hackr.hackr_alias}")
    expect(page).to have_content("MEMBER SINCE")
    expect(page).to have_content("WIRE PULSES")
    expect(page).to have_content("Ghost in the wire")
    expect(page).to have_content("My own broadcast")
    expect(page).to have_content("@#{hackr.hackr_alias} echoed")
    expect(page).to have_content("Someone else's signal")
  end

  it "edits the bio inline through the turbo frame" do
    log_in!
    visit "/wire/#{hackr.hackr_alias.downcase}"

    page.execute_script("window.__turbo_marker = true")
    click_link "✎ EDIT"
    expect(page).to have_field("bio", with: "Ghost in the wire")

    fill_in "bio", with: "Rewired and broadcasting."
    click_button "SAVE"

    expect(page).to have_content("Rewired and broadcasting.")
    expect(page).to have_link("✎ EDIT") # back to view state
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # frame, not reload
    expect(hackr.reload.bio).to eq("Rewired and broadcasting.")
  end

  it "pins, reorders, and unpins own pulses" do
    a = create(:pulse, grid_hackr: hackr, content: "Pin candidate Alpha")
    b = create(:pulse, grid_hackr: hackr, content: "Pin candidate Beta")
    log_in!
    visit "/wire/#{hackr.hackr_alias.downcase}"

    within("#pulse_#{a.id}") { find(".pin-button").click }
    expect(page).to have_content("📌 PINNED")
    within("#pulse_#{b.id}") { find(".pin-button").click }

    within(".pinned-pulses") do
      expect(page).to have_content("Pin candidate Alpha")
      expect(page).to have_content("Pin candidate Beta")
      # Move Beta up over Alpha
      within("#pulse_#{b.id}") { find(".pin-move-button", text: "↑").click }
    end
    expect(hackr.pulse_pins.order(:position).map(&:pulse_id)).to eq([b.id, a.id])

    within(".pinned-pulses") do
      within("#pulse_#{a.id}") { find(".pin-button--pinned").click }
    end
    expect(hackr.pulse_pins.count).to eq(1)
    # Alpha returns to the timeline exactly once
    expect(page).to have_css(".user-timeline #pulse_#{a.id}", count: 1)
  end
end
