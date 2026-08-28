require "rails_helper"

# Phase 5: Uplink chat on Turbo Streams. The two-session example is the
# phase's exit criterion — a packet sent in one browser session appears
# live in another via the uplink_html stream while the JSON LiveChatChannel
# keeps serving relay/synthia (dual-publish). Presence counts ride the
# JSON channel into the uplink Stimulus controller.
RSpec.describe "Hotwire uplink", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }
  let!(:other) { create(:grid_hackr, password: "hackthegrid") }
  let!(:operator) { create(:grid_hackr, :operator, password: "hackthegrid") }
  let!(:channel) { create(:chat_channel, slug: "ambient", name: "#ambient") }

  def log_in!(as)
    visit "/grid/login"
    fill_in "hackr_alias", with: as.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  def await_uplink!
    expect(page).to have_content("UPLINK")
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
  end

  it "sends a packet and appends it without reload, with presence connected" do
    log_in!(hackr)
    visit "/uplink"
    await_uplink!

    # Presence rides the JSON channel into the Stimulus controller.
    expect(page).to have_content("operative", wait: 10)
    expect(page).to have_content("connected")

    expect(page).to have_button("TX", disabled: true)
    page.execute_script("window.__turbo_marker = true")

    fill_in "content", with: "First uplink transmission."
    expect(page).to have_button("TX", disabled: false)
    click_button "TX"

    expect(page).to have_content("First uplink transmission.", wait: 10)
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # no reload
    expect(page).to have_field("content", with: "") # input reset
    expect(ChatMessage.last.content).to eq("First uplink transmission.")
  end

  it "delivers packets sent in one session to another live (exit criterion)" do
    using_session(:viewer) do
      log_in!(hackr)
      visit "/uplink"
      await_uplink!
      page.execute_script("window.__turbo_marker = true")
    end

    using_session(:poster) do
      log_in!(other)
      visit "/uplink"
      await_uplink!
      fill_in "content", with: "Cross-session packet test."
      click_button "TX"
      expect(page).to have_content("Cross-session packet test.", wait: 10)
    end

    using_session(:viewer) do
      expect(page).to have_content("Cross-session packet test.", wait: 10)
      expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # arrived via stream
    end
  end

  it "round-trips moderation: drop redacts everywhere, restore brings it back" do
    packet = create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Moderation target")

    using_session(:viewer) do
      log_in!(hackr)
      visit "/uplink"
      await_uplink!
      expect(page).to have_content("Moderation target")
      # Operatives get no controls on someone else's packet.
      expect(page).not_to have_css("#chat_message_#{packet.id} button[title='Drop packet']")
    end

    using_session(:moderator) do
      log_in!(operator)
      visit "/uplink"
      await_uplink!
      # Revealed by the packet controller from the role meta.
      within("#chat_message_#{packet.id}") do
        expect(page).to have_css("button[title='Drop packet']", wait: 5)
        find("button[title='Drop packet']").click
      end
      expect(page).to have_content("[PACKET DROPPED]", wait: 10)
      expect(page).not_to have_content("Moderation target")
    end

    using_session(:viewer) do
      expect(page).to have_content("[PACKET DROPPED]", wait: 10)
      expect(page).not_to have_content("Moderation target")
    end

    using_session(:moderator) do
      within("#chat_message_#{packet.id}") do
        expect(page).to have_css("button[title='Restore packet']", wait: 5)
        find("button[title='Restore packet']").click
      end
      expect(page).to have_content("Moderation target", wait: 10)
    end

    using_session(:viewer) do
      expect(page).to have_content("Moderation target", wait: 10)
    end
  end

  it "switches channels via the tabs" do
    trace = create(:chat_channel, slug: "trace", name: "#trace")
    create(:chat_message, chat_channel: trace, grid_hackr: other, content: "Trace channel packet")

    log_in!(hackr)
    visit "/uplink"
    await_uplink!

    click_link "#trace"

    expect(page).to have_current_path("/uplink?channel=trace")
    expect(page).to have_content("Trace channel packet")
    expect(page).to have_css(".channel-tab--active", text: "#trace")
  end

  it "docks the chat on the live home page and sends from there" do
    create(:hackr_stream, artist: create(:artist), title: "DOCK SESSIONS",
      is_live: true, live_url: "https://www.youtube.com/watch?v=abc123xyz00")
    create(:chat_channel, :livestream_only, slug: "live", name: "#live")

    log_in!(hackr)
    visit "/"
    await_uplink!

    expect(page).to have_css(".live-side-panel--uplink")
    fill_in "content", with: "Docked transmission."
    click_button "TX"

    expect(page).to have_content("Docked transmission.", wait: 10)
    expect(ChatMessage.last.chat_channel.slug).to eq("live")
    expect(ChatMessage.last.hackr_stream).to be_present
  end

  it "serves the popout slim page with the heartbeat" do
    create(:hackr_stream, artist: create(:artist), is_live: true,
      live_url: "https://www.youtube.com/watch?v=abc123xyz00")
    create(:chat_channel, :livestream_only, slug: "live", name: "#live")
    create(:chat_message, chat_channel: ChatChannel.find_by(slug: "live"), grid_hackr: other, content: "Popout packet")

    visit "/uplink/popout" # public — no login
    await_uplink!

    expect(page).to have_content("Popout packet")
    expect(page).to have_content("to transmit packets") # anonymous prompt
    expect(page).not_to have_css(".header-nav") # slim layout: no site nav

    heartbeat = nil
    10.times do
      heartbeat = page.evaluate_script("localStorage.getItem('uplink_popout_heartbeat')")
      break if heartbeat
      sleep 0.2
    end
    expect(heartbeat).to be_present
  end

  it "keeps the permanent player alive navigating vault → uplink (Turbo nav)" do
    artist = create(:artist, name: "Wave Artist")
    release = create(:release, artist: artist)
    create(:track, :with_audio, artist: artist, release: release, title: "Uplink Tone")

    log_in!(hackr)
    visit "/vault"
    find(".track-row", text: "Uplink Tone").click
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn", wait: 10)
    page.execute_script("window.__player_marker = true")

    find(".header-nav-item a[href='/uplink']").click

    expect(page).to have_current_path("/uplink")
    expect(page).to have_content("UPLINK")
    expect(page).to have_css(".player-bar", visible: :visible)
    expect(page.evaluate_script("document.querySelector('#player-bar audio').paused")).to eq(false)
    # Marker survives ⇒ Turbo visit, not a full load
    expect(page.evaluate_script("window.__player_marker")).to eq(true)
  end
end
