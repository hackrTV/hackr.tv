require "rails_helper"

# Phase 4 exit criterion for the permanent player: playback started in the
# vault survives a Turbo visit to another page, and the queue captured at
# click time keeps advancing there (the 2s spike tone ends quickly).
RSpec.describe "Hotwire permanent player", type: :system do
  let(:artist) { create(:artist, name: "Wave Artist") }
  let(:release) { create(:release, artist: artist) }

  def audio_js(expr)
    page.evaluate_script("document.querySelector('#player-bar audio').#{expr}")
  end

  it "keeps playing across Turbo visits and auto-advances the queue" do
    create(:track, :with_audio, artist: artist, release: release, title: "First Tone", track_number: 1)
    create(:track, :with_audio, artist: artist, release: release, title: "Second Tone", track_number: 2)

    visit "/vault"
    expect(page).to have_content("PULSE VAULT")
    expect(page).to have_css(".track-row", text: "First Tone")

    find(".track-row", text: "First Tone").click

    # Bar appears with the track loaded and audio actually progressing
    expect(page).to have_css(".player-bar", visible: :visible, wait: 10)
    expect(page).to have_css("#track-title", text: "First Tone")
    expect(page).to have_css(".track-row--active", text: "First Tone")
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn", wait: 10)

    # --- Turbo visit away: playback must survive the body swap ---
    # (scripted Turbo.visit: the fixed statusbar sits under the player bar,
    # so its links aren't clickable while the bar is up — same as the SPA)
    page.execute_script("window.Turbo.visit('/wire')")
    expect(page).to have_current_path("/wire")

    expect(page).to have_css(".player-bar", visible: :visible)
    expect(page.evaluate_script("document.querySelectorAll('#player-bar audio').length")).to eq(1)

    # Queue advances to the second track when the 2s tone ends. Generous
    # wait: under full-suite CPU load headless audio can stutter, which
    # stretches the 2s tone well past wall-clock (observed flake).
    expect(page).to have_css("#track-title", text: "Second Tone", wait: 30)
    expect(audio_js("paused")).to eq(false)
  end

  it "survives real nav-menu navigation to an artist page (HOTWIRE_PATHS regression)" do
    create(:artist, name: "The.CyberPul.se", slug: "thecyberpulse")
    create(:track, :with_audio, artist: artist, release: release, title: "Nav Tone")

    visit "/vault"
    find(".track-row", text: "Nav Tone").click
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn", wait: 10)

    # The reported bug: artist slugs missing from HOTWIRE_PATHS made these
    # nav links data-turbo=false → full page load → player killed.
    find(".header-dropdown", text: "The.CyberPul.se").click
    find(".header-dropdown-content a[href='/thecyberpulse']", visible: :all).click

    expect(page).to have_current_path("/thecyberpulse")
    expect(page).to have_css(".player-bar", visible: :visible)
    expect(page.evaluate_script("document.querySelector('#player-bar audio').paused")).to eq(false)
    expect(page.evaluate_script("window.__player_regression_marker = true; true")).to eq(true)

    # And onward to a second artist route — still the same page session
    find(".header-dropdown", text: "The.CyberPul.se").click
    find(".header-dropdown-content a[href='/thecyberpulse/bio']", visible: :all).click
    expect(page).to have_current_path("/thecyberpulse/bio")
    expect(page).to have_css(".player-bar", visible: :visible)
    expect(page.evaluate_script("document.querySelector('#player-bar audio').paused")).to eq(false)
    # Marker survives ⇒ these were Turbo visits, not full loads
    expect(page.evaluate_script("window.__player_regression_marker")).to eq(true)
  end

  it "toggles pause from the bar and repaints vault highlights" do
    create(:track, :with_audio, artist: artist, release: release, title: "Only Tone")

    visit "/vault"
    find(".track-row", text: "Only Tone").click
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn", wait: 10)

    find("#play-pause-btn").click
    expect(page).to have_button("► PLAY", id: "play-pause-btn")
    expect(audio_js("paused")).to eq(true)
    expect(page).to have_no_css(".track-row--active")

    # Row click on the paused current track resumes instead of restarting
    find(".track-row", text: "Only Tone").click
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn")
    expect(audio_js("paused")).to eq(false)
  end

  it "filters the vault and scopes the queue to visible rows" do
    create(:track, :with_audio, artist: artist, release: release, title: "Alpha Signal", track_number: 1)
    create(:track, :with_audio, artist: artist, release: release, title: "Beta Signal", track_number: 2)
    other = create(:artist, name: "Other Artist")
    create(:track, :with_audio, artist: other, release: create(:release, artist: other), title: "Gamma Noise")

    visit "/vault"
    fill_in "track-search", with: "signal"

    expect(page).to have_css(".track-row", text: "Alpha Signal")
    expect(page).to have_no_css("table .track-row:not([hidden])", text: "Gamma Noise")

    find(".track-row", text: "Alpha Signal").click
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn", wait: 10)

    # Queue = the two visible tracks; the filtered-out one never plays
    expect(page).to have_css("#track-title", text: "Beta Signal", wait: 30)
    expect(page).to have_css("#track-title", text: "Alpha Signal", wait: 30)
  end
end
