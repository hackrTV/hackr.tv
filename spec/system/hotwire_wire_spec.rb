require "rails_helper"

# Phase 3: the WIRE on Turbo Streams. The two-session example is the
# phase's exit criterion — a pulse posted in one browser session appears
# live in another via the wire_html stream (dual-publish keeps the JSON
# channel for overlays).
RSpec.describe "Hotwire wire feed", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }
  let!(:other) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(as)
    visit "/grid/login"
    fill_in "hackr_alias", with: as.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  it "composes with a live counter and prepends the pulse without reload" do
    log_in!(hackr)
    visit "/wire"

    expect(page).to have_content("The WIRE")
    expect(page).to have_content("256 / 256")
    expect(page).to have_button("Broadcast", disabled: true)

    fill_in "content", with: "First transmission from the Hotwire."
    expect(page).to have_content("#{256 - 36} / 256")
    expect(page).to have_button("Broadcast", disabled: false)

    page.execute_script("window.__turbo_marker = true")
    click_button "Broadcast"

    expect(page).to have_content("First transmission from the Hotwire.")
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # no reload
    expect(page).to have_field("content", with: "") # composer reset
    expect(Pulse.last.content).to eq("First transmission from the Hotwire.")
  end

  it "delivers a pulse posted in one session to another live (exit criterion)" do
    using_session(:viewer) do
      visit "/wire"
      expect(page).to have_content("The WIRE")
      expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
      page.execute_script("window.__turbo_marker = true")
    end

    using_session(:poster) do
      log_in!(other)
      visit "/wire"
      fill_in "content", with: "Cross-session signal test."
      click_button "Broadcast"
      expect(page).to have_content("Cross-session signal test.")
    end

    using_session(:viewer) do
      expect(page).to have_content("Cross-session signal test.", wait: 10)
      expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # arrived via stream
    end
  end

  it "toggles echoes and pushes count updates to other sessions" do
    pulse = create(:pulse, grid_hackr: other, content: "Echo relay target")

    using_session(:viewer) do
      visit "/wire"
      expect(page).to have_content("Echo relay target")
      expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
    end

    using_session(:echoer) do
      log_in!(hackr)
      visit "/wire"
      within("#pulse_#{pulse.id}") { find(".echo-button").click }
      expect(page).to have_css("#pulse_#{pulse.id} .echo-button.echoed", wait: 10)
      expect(page).to have_css("#pulse_#{pulse.id} .echo-count", text: "1")
    end

    using_session(:viewer) do
      expect(page).to have_css("#pulse_#{pulse.id} .echo-count", text: "1", wait: 10)
      expect(page).to have_no_css("#pulse_#{pulse.id} .echo-button.echoed") # per-viewer state untouched
    end
  end

  it "reveals owner controls and deletes everywhere" do
    pulse = create(:pulse, grid_hackr: hackr, content: "Doomed broadcast")

    using_session(:viewer) do
      visit "/wire"
      expect(page).to have_content("Doomed broadcast")
      expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
    end

    using_session(:owner) do
      log_in!(hackr)
      visit "/wire"
      within("#pulse_#{pulse.id}") { find(".delete-button").click }
      expect(page).to have_no_content("Doomed broadcast", wait: 10)
    end

    using_session(:viewer) do
      expect(page).to have_no_content("Doomed broadcast", wait: 10)
    end
  end

  it "splices from the inline reply form onto the thread page" do
    root = create(:pulse, grid_hackr: other, content: "Root of the thread")
    log_in!(hackr)
    visit "/wire"

    within("#pulse_#{root.id}") { find(".splice-button").click }
    within("#pulse_#{root.id}") do
      fill_in "content", with: "Spliced response."
      click_button "Splice"
    end

    expect(page).to have_current_path("/wire/pulse/#{root.id}")
    expect(page).to have_content("Root of the thread")
    expect(page).to have_content("Spliced response.")
    expect(page).to have_content("2 pulses")
  end
end
