require "rails_helper"

# Phase 0 spike A: an <audio> inside a data-turbo-permanent element must
# keep playing across Turbo visits, restore visits (back button), and a
# form-redirect refresh. Findings feed phase_4_player_music.md.
RSpec.describe "Hotwire player spike", type: :system do
  def audio_js(expr)
    page.evaluate_script("document.querySelector('#spike-player audio').#{expr}")
  end

  it "keeps audio playing across Turbo visits, back navigation, and refresh" do
    visit "/dev/hotwire/player/a"
    click_button "PLAY/PAUSE"
    expect(page).to have_css("[data-spike-player-target='status']", text: "playing")

    # Wait until playback has measurably advanced
    expect(page).to have_css("[data-spike-player-target='time']", text: /[1-9]/, wait: 10)

    # --- Turbo visit A → B ---
    t_before = audio_js("currentTime")
    click_link "→ page B"
    expect(page).to have_content("PLAYER SPIKE — PAGE B")

    expect(audio_js("paused")).to eq(false)
    expect(audio_js("currentTime")).to be >= t_before
    expect(page.evaluate_script("document.querySelectorAll('#spike-player').length")).to eq(1)
    expect(page.evaluate_script("document.querySelectorAll('#spike-player audio').length")).to eq(1)

    # --- restore visit (back button) ---
    page.go_back
    expect(page).to have_content("PLAYER SPIKE — PAGE A")
    expect(audio_js("paused")).to eq(false)
    expect(page.evaluate_script("document.querySelectorAll('#spike-player audio').length")).to eq(1)

    # --- form submit → redirect back to the same page ---
    t_before_refresh = audio_js("currentTime")
    click_button "same-page refresh (redirect)"
    expect(page).to have_content("PLAYER SPIKE — PAGE A")
    expect(audio_js("paused")).to eq(false)
    expect(audio_js("currentTime")).to be >= t_before_refresh
  end
end
