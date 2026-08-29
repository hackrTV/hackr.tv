require "rails_helper"

# Phase 4: radio station playback through the permanent player — station
# context (seek disabled, forced shuffle, station name in the bar) and the
# tune-in credit for logged-in listeners.
RSpec.describe "Hotwire radio", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  def build_playlist_station(name)
    artist = create(:artist)
    release = create(:release, artist: artist)
    station = create(:radio_station, name: name, stream_url: "")
    playlist = create(:playlist)
    %w[One Two].each_with_index do |suffix, i|
      track = create(:track, :with_audio, artist: artist, release: release,
        title: "#{name} #{suffix}", track_number: i + 1)
      create(:playlist_track, playlist: playlist, track: track)
    end
    create(:radio_station_playlist, radio_station: station, playlist: playlist)
    station
  end

  it "tunes into a station: shuffled queue, disabled seek, tune credit" do
    station = build_playlist_station("Night Static")

    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")

    visit "/fm/radio"
    expect(page).to have_content("FRACTURE NETWORK RADIO STATIONS")

    click_button "▶ PLAY STATION"

    # Bar in station mode: station name shown, transport controls hidden
    expect(page).to have_css(".player-bar", visible: :visible, wait: 10)
    expect(page).to have_css("[data-player-target='stationName']", text: "Night Static", wait: 10)
    expect(page).to have_css("[data-player-target='seekBar'][disabled]")
    expect(page).to have_no_css("[data-player-target='controls']:not([hidden]) button")
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn", wait: 10)

    # Station button reflects playing state; toggling pauses the player
    expect(page).to have_button("❚❚ PAUSE", class: "tune-in-btn", wait: 10)

    # tune_in credited exactly once for this hackr
    deadline = Time.current + 10
    sleep 0.2 while HackrRadioTune.where(grid_hackr: hackr, radio_station: station).count.zero? && Time.current < deadline
    expect(HackrRadioTune.where(grid_hackr: hackr, radio_station: station).count).to eq(1)
  end

  it "keeps station playback alive across a Turbo visit" do
    build_playlist_station("Drift FM")

    visit "/fm/radio"
    click_button "▶ PLAY STATION"
    expect(page).to have_css("[data-player-target='stationName']", text: "Drift FM", wait: 10)

    page.execute_script("window.Turbo.visit('/vault')")
    expect(page).to have_current_path("/vault")
    expect(page).to have_css(".player-bar", visible: :visible)
    expect(page).to have_css("[data-player-target='stationName']", text: "Drift FM")
    expect(page.evaluate_script("document.querySelector('#player-bar audio').paused")).to eq(false)
  end
end
