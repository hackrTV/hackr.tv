require "rails_helper"

# Phase 4: playlist pages end-to-end — dialog create, reorder persistence
# through the API endpoint, autoplay handoff to the permanent player.
RSpec.describe "Hotwire playlists", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }
  let(:artist) { create(:artist) }
  let(:release) { create(:release, artist: artist) }

  def login
    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  it "creates a playlist through the dialog" do
    login
    visit "/fm/playlists"
    expect(page).to have_content("NO PLAYLISTS YET")

    click_button "Create Your First Playlist"
    within(".playlist-dialog") do
      fill_in "playlist_name", with: "Midnight Mix"
      click_button "Create"
    end

    expect(page).to have_content("Midnight Mix")
    expect(page).to have_content("0 tracks")
    expect(hackr.playlists.count).to eq(1)
  end

  it "reorders tracks with the move buttons and persists" do
    login
    playlist = create(:playlist, grid_hackr: hackr, name: "Order Test")
    %w[Alpha Beta Gamma].each_with_index do |name, i|
      track = create(:track, :with_audio, artist: artist, release: release, title: name, track_number: i + 1)
      create(:playlist_track, playlist: playlist, track: track)
    end

    visit "/fm/playlists/#{playlist.id}"
    expect(page).to have_css(".playlist-table__row", count: 3)

    within(all(".playlist-table__row")[2]) { find("button[title='Move up']").click }

    expect(page).to have_css(".playlist-table__row:nth-child(2) .playlist-table__title", text: "Gamma")

    deadline = Time.current + 10
    sleep 0.2 while playlist.playlist_tracks.reload.order(:position).map { |pt| pt.track.title } != %w[Alpha Gamma Beta] && Time.current < deadline
    expect(playlist.playlist_tracks.order(:position).map { |pt| pt.track.title }).to eq(%w[Alpha Gamma Beta])
  end

  it "autoplays from the index Play button and strips the param" do
    login
    playlist = create(:playlist, grid_hackr: hackr, name: "Auto Mix")
    track = create(:track, :with_audio, artist: artist, release: release, title: "Instant Tone")
    create(:playlist_track, playlist: playlist, track: track)

    visit "/fm/playlists"
    click_link "▶ Play"

    expect(page).to have_css(".player-bar", visible: :visible, wait: 10)
    expect(page).to have_css("#track-title", text: "Instant Tone")
    expect(page.current_url).not_to include("autoplay")
  end

  it "edits playlist details inline" do
    login
    playlist = create(:playlist, grid_hackr: hackr, name: "Rename Me")

    visit "/fm/playlists/#{playlist.id}"
    click_button "✎ Edit"
    fill_in "edit_playlist_name", with: "Renamed Set"
    check "playlist[is_public]"
    click_button "Save"

    expect(page).to have_content("Renamed Set")
    expect(page).to have_button("🔗 Share")
    expect(playlist.reload.is_public).to be(true)
  end
end
