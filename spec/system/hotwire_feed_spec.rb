require "rails_helper"

# Phase 3: world feed terminal — typed initial render + live appends via
# the Publisher's dual-publish.
RSpec.describe "Hotwire world feed", type: :system do
  before { WorldEventSetting.current.update!(visible: true) }

  it "types the initial events" do
    WorldEvent.create!(event_type: "hackr_registered", hackr_alias: "GhostWire", data: {})

    visit "/feed"

    expect(page).to have_content("HACKR.TV // WORLD FEED")
    # typed-line runs at 16ms/char — wait for the full line
    expect(page).to have_content("GhostWire jacked into THE PULSE GRID for the first time", wait: 10)
    expect(page).to have_content("1 events loaded")
  end

  it "appends and types live events over the stream" do
    visit "/feed"
    expect(page).to have_content("Awaiting signal...")
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
    page.execute_script("window.__turbo_marker = true")

    WorldEventFeed::Publisher.publish(
      event_type: "clearance_up", hackr_alias: "NullSec", data: {new_clearance: 7}
    )

    expect(page).to have_content("NullSec reached CLEARANCE 7", wait: 10)
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true)
  end

  it "hides the feed from non-admins when not visible" do
    WorldEventSetting.current.update!(visible: false)

    visit "/feed"

    expect(page).to have_current_path("/")
  end
end
