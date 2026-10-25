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

  it "autocompletes :slug: emotes from the composer and renders them in the log" do
    create(:emote, slug: "wave")
    log_in!(hackr)
    visit "/uplink"
    await_uplink!

    # One send_keys: Cuprite clicks the field before every send_keys, and
    # a click that lands inside the ":wa" token moves the caret off it and
    # closes the picker (as it would for a real click), so the Enter that
    # picks has to ride the same keystroke batch as the typing.
    find_field("content").send_keys("o/ :wa", :enter) # Enter picks the emote, must NOT submit
    expect(page).to have_field("content", with: "o/ :wave: ")
    expect(page).to have_no_css(".emote-menu .emote-option")
    expect(ChatMessage.count).to eq(0)

    click_button "TX"
    expect(page).to have_css("#uplink-log img.emote[alt=':wave:']", wait: 10)
    expect(ChatMessage.last.content).to include(":wave:")
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
      # Revealed by the packet controller from the role meta; the shell
      # shows packet controls on hover (Discord rhythm).
      find("#chat_message_#{packet.id}").hover
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
      find("#chat_message_#{packet.id}").hover
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

  it "switches channels via the sidebar" do
    trace = create(:chat_channel, slug: "trace", name: "#trace")
    create(:chat_message, chat_channel: trace, grid_hackr: other, content: "Trace channel packet")

    log_in!(hackr)
    visit "/uplink"
    await_uplink!

    click_link "#trace"

    expect(page).to have_current_path("/uplink?channel=trace")
    expect(page).to have_content("Trace channel packet")
    expect(page).to have_css(".uplink-channel--active", text: "#trace")
    expect(page).to have_css(".uplink-chanhead-name", text: "#trace")
  end

  it "groups consecutive packets by one author, sends multi-line packets on Enter, and reveals only your own roster row" do
    create(:chat_message, chat_channel: channel, grid_hackr: other, content: "first from other")
    create(:chat_message, chat_channel: channel, grid_hackr: other, content: "second from other")

    using_session(:lurker) do
      log_in!(other)
      visit "/uplink"
      await_uplink!
    end

    log_in!(hackr)
    visit "/uplink"
    await_uplink!

    # Discord rhythm: the second consecutive packet collapses its author line.
    expect(page).to have_css(".packet--cont", text: "second from other")
    expect(page).not_to have_css(".packet--cont", text: "first from other")

    # Shift+Enter keeps typing, Enter sends; the stored packet keeps the newline.
    find_field("content").send_keys("line one", [:shift, :enter], "line two")
    expect(ChatMessage.count).to eq(2)
    find_field("content").send_keys(:enter)
    expect(page).to have_css("#uplink-log .packet-content", text: "line one\nline two", wait: 10)
    expect(ChatMessage.last.content).to eq("line one\nline two")
    expect(page).to have_field("content", with: "")

    # Operatives pane: the lurker is a callsign, you are you.
    within("#uplink-members") do
      expect(page).to have_content(Uplink::Callsign.label(other.id), wait: 10)
      expect(page).not_to have_content(other.hackr_alias)
      expect(page).to have_css(".uplink-member--self", text: "@#{hackr.hackr_alias}", wait: 10)
    end
  end

  it "scrolls back through the channel's history page by page without moving the viewport, grouping across pages" do
    now = Time.current
    ChatMessage.insert_all((1..70).map { |i|
      {chat_channel_id: channel.id, grid_hackr_id: other.id, content: "archive #{i}",
       created_at: now - (70 - i).seconds, updated_at: now}
    })
    oldest = channel.chat_messages.order(:id).first

    log_in!(hackr)
    visit "/uplink"
    await_uplink!
    expect(page).to have_content("archive 70")
    expect(page).to have_css(".uplink-log-top[data-more='true']", visible: :all)

    # 20 on render, then 40 + 10 as the top sentinel scrolls into view
    # (a page may already be loading if the first 20 didn't fill the log).
    # Scrolling to the top and reading the first packet's text position
    # happen in one script, so no splice can land in between; after the
    # page arrives the text must not have moved. (The packet's box does
    # shift: it loses its author line when it becomes a continuation of
    # the spliced group — the text the viewer is reading stays put.)
    measure = <<~JS
      (() => {
        const log = document.getElementById("uplink-log")
        log.scrollTop = 0
        const first = log.querySelector(".packet")
        return [first.id, first.querySelector(".packet-content").getBoundingClientRect().top]
      })()
    JS
    3.times do
      break if page.has_css?(".uplink-log-top[data-more='false']", visible: :all, wait: 0)
      count = page.all(".packet").size
      id, top = page.evaluate_script(measure)
      expect(page).to have_css(".packet", minimum: count + 1, wait: 10)
      expect(page).to have_no_css(".uplink-log-top[data-loading]", visible: :all, wait: 10)
      after = page.evaluate_script("document.querySelector('##{id} .packet-content').getBoundingClientRect().top")
      expect(after).to be_within(1).of(top)
    end

    expect(page).to have_css("#chat_message_#{oldest.id}")
    expect(page).to have_css(".packet", count: 70)
    expect(page).to have_css(".uplink-log-top[data-more='false']") # visible: the beginning-of-channel strip
    expect(page).to have_css(".packet:not(.packet--cont)", count: 1) # one author, one group across both seams
    expect(page).to have_css("#chat_message_#{oldest.id}:not(.packet--cont)")
    expect(page).not_to have_css(".uplink-jump", visible: :visible) # history is never "new packets"
  end

  it "toasts an @mention to a hackr reading another channel, badges that sidebar row, and the toast opens the channel" do
    create(:chat_channel, slug: "trace", name: "#trace")

    using_session(:mentioned) do
      log_in!(other)
      visit "/uplink?channel=trace"
      await_uplink!
      # uplink_html + uplink_members + the layout's per-hackr toasts stream
      expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, count: 3, wait: 10)
    end

    using_session(:sender) do
      log_in!(hackr)
      visit "/uplink"
      await_uplink!
      fill_in "content", with: "ping @#{other.hackr_alias.upcase} over here"
      click_button "TX"
      expect(page).to have_content("over here", wait: 10)
    end

    using_session(:mentioned) do
      expect(page).to have_css(".toast--mention", wait: 10)
      within(".toast--mention") do
        expect(page).to have_content("@MENTION")
        expect(page).to have_content("#ambient")
        expect(page).to have_content("@#{hackr.hackr_alias}")
        expect(page).to have_content("over here")
      end
      expect(page).to have_css(".uplink-channel--mention[data-channel='ambient'] .uplink-channel-badge", text: "@")
      expect(page).to have_no_css(".uplink-channel--mention[data-channel='trace']")

      find(".toast--mention").click
      expect(page).to have_current_path("/uplink?channel=ambient")
      expect(page).to have_css(".uplink-mention--self", text: "@#{other.hackr_alias.upcase}", wait: 10)
      expect(page).to have_no_css(".toast--mention")
      expect(page).to have_no_css(".uplink-channel-badge") # the visit re-rendered the list
    end
  end

  it "replies from the hover control: the bar names the author, Escape disarms, the reply quotes the parent for both sessions and jumps to it" do
    parent = create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Original transmission")

    using_session(:author) do
      log_in!(other)
      visit "/uplink"
      await_uplink!
    end

    log_in!(hackr)
    visit "/uplink"
    await_uplink!
    fill_in "content", with: "my own first"
    click_button "TX"
    expect(page).to have_css("#uplink-log .packet-content", text: "my own first", wait: 10)

    # The control shows on hover (Cuprite treats opacity:0 as invisible).
    arm = lambda do
      find("#chat_message_#{parent.id}").hover
      within("#chat_message_#{parent.id}") { find("button[title='Reply to packet']", wait: 5).click }
      expect(page).to have_css(".packet-reply-bar-sender", text: "@#{other.hackr_alias}")
      expect(find("#reply_to_id", visible: :all).value).to eq(parent.id.to_s)
    end

    arm.call
    find_field("content").send_keys(:escape)
    expect(page).to have_no_css(".packet-reply-bar")
    expect(find("#reply_to_id", visible: :all).value).to eq("")

    arm.call
    find_field("content").send_keys("replying here", :enter)
    expect(page).to have_css(".packet--reply[data-reply-to='#{parent.id}']", wait: 10)
    within(".packet--reply") do
      expect(page).to have_css(".packet-reply-quote", text: "[>] @#{other.hackr_alias} Original transmission")
      expect(page).to have_content("replying here")
    end
    expect(page).to have_no_css(".packet-reply-bar") # disarmed by the send
    expect(page).to have_field("content", with: "")
    expect(ChatMessage.last.reply_to).to eq(parent)
    # Right after your own packet, a reply still starts its own group.
    expect(page).to have_css(".packet--reply:not(.packet--cont)")

    find(".packet--reply .packet-reply-quote").click
    expect(page).to have_css("#chat_message_#{parent.id}.packet--flash")
    expect(page).to have_no_css(".packet--flash", wait: 5)

    using_session(:author) do
      expect(page).to have_css(".packet--reply .packet-reply-quote", text: "@#{other.hackr_alias} Original transmission", wait: 10)
      expect(page).to have_content("replying here")
    end
  end

  it "opens the operative record from a packet author without leaving the page, and closes it on Escape and outside clicks" do
    other.update!(bio: "Grid runner since the first breach.", stats: {"clearance" => 4}, last_activity_at: Time.current)
    create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Signal check")
    create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Second packet")
    log_in!(hackr)
    visit "/uplink"
    await_uplink!

    first(".packet-author", text: "@#{other.hackr_alias}").click
    within("#uplink-popover") do
      expect(page).to have_css(".uplink-popover-alias", text: "@#{other.hackr_alias}", wait: 10)
      expect(page).to have_css(".uplink-popover-badge", text: "OPERATIVE")
      expect(page).to have_content("CL4")
      expect(page).to have_content("ONLINE NOW")
      expect(page).to have_content("Grid runner since the first breach.")
      expect(page).to have_css(".uplink-popover-stat", text: /2\s*PACKETS/)
      expect(page).to have_link("[WIRE PROFILE]", href: "/wire/#{other.hackr_alias.downcase}")
    end
    expect(page).to have_current_path("/uplink") # the author link's own href (the WIRE profile) was not followed
    expect(page.evaluate_script("document.activeElement.className")).to eq("uplink-popover")

    find(".uplink-popover").send_keys(:escape)
    expect(page).to have_no_css(".uplink-popover")
    expect(page).to have_css("#uplink-popover", visible: :hidden)

    first(".packet-author", text: "@#{other.hackr_alias}").click
    expect(page).to have_css(".uplink-popover-alias", text: "@#{other.hackr_alias}", wait: 10)
    find(".uplink-chanhead-name").click # anywhere outside the card
    expect(page).to have_no_css(".uplink-popover")
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
