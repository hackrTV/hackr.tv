require "rails_helper"

# Phase 3: server-rendered home — terminal boot sequence, command input,
# live-stream state, and the watch-time subscription.
RSpec.describe "Hotwire home page", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  it "types the boot sequence, skips on keydown, and rejects unknown commands" do
    visit "/"

    expect(page).to have_content("HACKR.TV BROADCAST SYSTEM", wait: 10)

    # Keydown skips straight to the full render + interactive prompt
    # (dispatched directly — cuprite doesn't emit keydown for bare modifiers)
    page.execute_script("document.dispatchEvent(new KeyboardEvent('keydown', {key: 'x'}))")
    expect(page).to have_content("TRANSMISSION READY. SELECT YOUR DESTINATION.", wait: 10)
    expect(page).to have_content("FEATURED ARTISTS:")
    expect(page).to have_content("PLATFORM SERVICES:")

    find(".terminal-hidden-input", visible: :all).send_keys("xyzzy", :enter)
    expect(page).to have_content("UNKNOWN COMMAND: xyzzy")
  end

  it "hides the docked Uplink while a popout window is alive" do
    create(:hackr_stream, artist: create(:artist), title: "LIVE TRANSMISSION",
      is_live: true, live_url: "https://www.youtube.com/embed/test123")
    create(:chat_channel, :livestream_only, slug: "live", name: "#live")

    visit "/"
    expect(page).to have_css(".live-side-panel--uplink")

    # The popout window stamps localStorage every 500ms (popout_heartbeat);
    # the uplink-dock controller hides the dock while the stamp is fresh
    # and restores it once the stamp is gone/stale. Same-window writes
    # fire no storage event, so this exercises the poll path.
    page.execute_script("localStorage.setItem('uplink_popout_heartbeat', String(Date.now()))")
    expect(page).to have_css(".live-embed.uplink-popped", wait: 5)
    expect(page).not_to have_css(".live-side-panel--uplink")

    page.execute_script("localStorage.removeItem('uplink_popout_heartbeat')")
    expect(page).not_to have_css(".live-embed.uplink-popped", wait: 5)
    expect(page).to have_css(".live-side-panel--uplink")
  end

  it "shows the live embed and accrues a watch session for logged-in viewers" do
    artist = create(:artist)
    create(:hackr_stream, artist: artist, title: "LIVE TRANSMISSION",
      is_live: true, live_url: "https://www.youtube.com/embed/test123")

    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")

    visit "/"
    expect(page).to have_content("LIVE TRANSMISSION")
    expect(page).to have_css(".live-video-frame iframe")
    expect(page).to have_link("OPEN UPLINK", href: "/uplink")

    # Theater mode hides the LIVE NOW bar so the embed + dock fill the
    # viewport; the floating [x] EXIT control (or Escape) returns.
    click_button "[=] THEATER"
    expect(page).to have_css(".live-embed.theater-mode")
    expect(page).not_to have_css(".live-now-bar")
    expect(page).to have_button("[x] EXIT")
    click_button "[x] EXIT"
    expect(page).not_to have_css(".live-embed.theater-mode")
    expect(page).to have_css(".live-now-bar")

    # stream-watch subscribes StreamWatchChannel → session row appears
    deadline = Time.current + 10
    sleep 0.2 while HackrWatchSession.where(grid_hackr: hackr).count.zero? && Time.current < deadline
    expect(HackrWatchSession.where(grid_hackr: hackr).count).to eq(1)
  end
end
