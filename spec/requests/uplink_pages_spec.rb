require "rails_helper"

# Server-rendered Uplink chat pages + form endpoints (Hotwire migration
# Phase 5). The JSON API keeps its own specs; the dual-publish broadcasts
# are covered in the ChatMessage model spec.
RSpec.describe "Uplink pages", type: :request do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }
  let!(:other) { create(:grid_hackr, password: "hackthegrid") }
  let!(:operator) { create(:grid_hackr, :operator, password: "hackthegrid") }
  let!(:channel) { create(:chat_channel, slug: "ambient", name: "#ambient") }

  def log_in!(as = hackr)
    post "/grid/login", params: {hackr_alias: as.hackr_alias, password: "hackthegrid"}
  end

  def turbo_stream_headers
    {"Accept" => "text/vnd.turbo-stream.html"}
  end

  describe "GET /uplink" do
    it "requires login" do
      get "/uplink"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/grid/login")
    end

    it "renders the shell with recent packets, composer, and stream subscription" do
      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Ambient signal check")
      create(:chat_message, :dropped, chat_channel: channel, grid_hackr: other, content: "Redacted transmission")
      log_in!

      get "/uplink"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("UPLINK")
      expect(response.body).to include("Ambient signal check")
      expect(response.body).not_to include("Redacted transmission") # dropped excluded from the initial log
      expect(response.body).to include("Transmit a packet...")
      expect(response.body).to include("turbo-cable-stream-source")
      expect(response.body).to include('data-uplink-channel-value="ambient"')
      expect(response.body).to include("No packets yet") # empty-state div always renders (CSS hides it)
    end

    it "switches channels via ?channel= and marks the active sidebar row" do
      trace = create(:chat_channel, slug: "trace", name: "#trace")
      create(:chat_message, chat_channel: trace, grid_hackr: other, content: "Trace-only packet")
      log_in!

      get "/uplink", params: {channel: "trace"}

      expect(response.body).to include('data-uplink-channel-value="trace"')
      expect(response.body).to include("Trace-only packet")
      expect(response.body).to include("uplink-channel uplink-channel--active")
      expect(response.body).to include('<h2 class="uplink-chanhead-name">#trace</h2>')
    end

    it "renders the NODE shell chrome: rail, categorized sidebar in position order, channel header with the topic" do
      create(:chat_channel, :livestream_only, slug: "live", name: "#live", category: "BROADCAST", position: 0)
      channel.update!(category: "COMMS", position: 10, description: "Always-on ambient comms.")
      create(:chat_channel, slug: "ops", name: "#ops", category: "COMMS", position: 20)
      log_in!

      get "/uplink"

      body = response.body
      expect(body).to include('class="uplink-shell" data-controller="uplink uplink-shell"')
      expect(body).to include("hackr.tv NODE")
      expect(body.index("BROADCAST")).to be < body.index("COMMS") # category order follows position
      expect(body.index(">#ambient<")).to be < body.index(">#ops<")
      expect(body).to include('<h2 class="uplink-chanhead-name">#ambient</h2>')
      expect(body).to include("Always-on ambient comms.") # description as the topic
      expect(body).not_to include("chrome-content") # no default chrome around the shell
      expect(body).to include(%(@#{hackr.hackr_alias})) # user panel
    end

    it "hooks the shell's log and composer: grouping on, multiline textarea, head metas" do
      log_in!

      get "/uplink"

      body = response.body
      expect(body).to include('data-packet-log-group-value="true"')
      expect(body).to include("<textarea") # shell composer is multiline
      expect(body).to include('data-packet-form-multiline-value="true"')
      expect(body).to include(%(<meta name="uplink-callsign" content="#{Uplink::Callsign.token(hackr.id)}">))
      expect(body).to include('turbo-cache-control" content="no-cache"')
    end

    it "lists the viewer in the roster from the first paint without writing a presence row" do
      log_in!

      get "/uplink"

      expect(response.body).to include('id="uplink-members"')
      expect(response.body).to include("OPERATIVE — 1")
      expect(response.body).to include(%(data-callsign="#{Uplink::Callsign.token(hackr.id)}"))
      expect(GridUplinkPresence.count).to eq(0) # the cable subscription creates it, not the GET
    end

    it "lists connected operatives as callsigns only, never aliases" do
      lurker = create(:grid_hackr, :operator)
      GridUplinkPresence.touch!(lurker, channel)
      log_in!

      get "/uplink"

      roster = response.body[/<div id="uplink-members".*?<\/div>/m]
      expect(roster).to include("OPERATOR — 1")
      expect(roster).to include("OPERATIVE — 1") # the viewer
      expect(roster).to include(Uplink::Callsign.label(lurker.id))
      expect(roster).to include(%(data-callsign="#{Uplink::Callsign.token(lurker.id)}"))
      expect(roster).not_to include(lurker.hackr_alias)
      expect(roster).not_to include(hackr.hackr_alias) # own row is revealed client-side only
      expect(roster).not_to include(%(data-callsign="#{lurker.id}"))
    end

    it "stages the live stream above the log on livestream channels only" do
      live = create(:chat_channel, :livestream_only, slug: "live", name: "#live")
      create(:hackr_stream, artist: create(:artist), title: "NODE SESSIONS", is_live: true,
        live_url: "https://www.youtube.com/embed/abc123xyz00")
      log_in!

      get "/uplink", params: {channel: "live"}
      expect(response.body).to include('class="uplink-stage"')
      expect(response.body).to include('data-src="https://www.youtube.com/embed/abc123xyz00"')
      expect(response.body).to include("NODE SESSIONS")
      expect(response.body).to include("[-] HIDE VIDEO")
      expect(response.body).to include("Transmit a packet...") # channel is open while live

      get "/uplink", params: {channel: "ambient"}
      expect(response.body).not_to include('class="uplink-stage"')
      expect(live.reload).to be_currently_available
    end

    it "seeds the scrollback sentinel from whether older packets exist and reloads the frame in shell mode" do
      log_in!

      get "/uplink"
      expect(response.body).to include('class="uplink-log-top" data-packet-log-target="top" data-more="false"')
      expect(response.body).to include('data-src="/uplink/log?channel=ambient"')
      expect(response.body).to include('data-uplink-log-src-value="/uplink/log?channel=ambient&amp;shell=1"')

      create_list(:chat_message, 21, chat_channel: channel, grid_hackr: other)
      get "/uplink"
      expect(response.body).to include('class="uplink-log-top" data-packet-log-target="top" data-more="true"')
      expect(response.body.scan(/id="chat_message_\d+"/).size).to eq(20)
      expect(response.body.index("uplink-log-top")).to be < response.body.index("chat_message_") # sentinel sits right before the packets
    end

    it "tags packets with the author key + timestamp the log groups on" do
      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "grouped?")
      log_in!

      get "/uplink"

      expect(response.body).to include(%(data-author-key="h#{other.id}"))
      expect(response.body).to match(/data-at="\d{13}"/)
    end

    it "falls back to the default channel for unknown slugs" do
      log_in!

      get "/uplink", params: {channel: "nope"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-uplink-channel-value="ambient"')
    end

    it "bounces role-gated channels back to the default" do
      create(:chat_channel, :operator_only, slug: "ops", name: "#ops")
      log_in!

      get "/uplink", params: {channel: "ops"}

      expect(response).to redirect_to("/uplink")
    end

    it "renders the offline state for livestream channels" do
      create(:chat_channel, :livestream_only, slug: "live", name: "#live")
      log_in!

      get "/uplink", params: {channel: "live"}

      expect(response.body).to include("#live is only available during livestreams.")
      expect(response.body).to include("Check back when we're live!")
      expect(response.body).not_to include("Transmit a packet...")
    end

    it "shows the squelch notice instead of the form" do
      create(:user_punishment, :squelch, grid_hackr: hackr)
      log_in!

      get "/uplink"

      expect(response.body).to include("You have been squelched.")
      expect(response.body).not_to include("Transmit a packet...")
    end

    it "shows the blackout notice instead of the form" do
      create(:user_punishment, :blackout, grid_hackr: hackr)
      log_in!

      get "/uplink"

      expect(response.body).to include("You have been blackedout from Uplink.")
      expect(response.body).not_to include("Transmit a packet...")
    end

    it "escapes packet content" do
      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "<script>alert(1)</script>")
      log_in!

      get "/uplink"

      expect(response.body).not_to include("<script>alert(1)</script>")
      expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
    end

    it "renders mentions as links and censors non-admin URLs" do
      create(:chat_message, chat_channel: channel, grid_hackr: other,
        content: "ping @#{hackr.hackr_alias} see https://example.com/x")
      log_in!

      get "/uplink"

      expect(response.body).to include(%(href="/wire/#{hackr.hackr_alias}"))
      expect(response.body).to include("uplink-mention")
      expect(response.body).to include("[LINK CENSORED BY GOVCORP]")
      expect(response.body).not_to include(%(href="https://example.com/x"))
    end

    it "renders admin URLs as live links" do
      admin = create(:grid_hackr, :admin)
      create(:chat_message, chat_channel: channel, grid_hackr: admin, content: "docs at https://example.com/x")
      log_in!

      get "/uplink"

      expect(response.body).to include(%(href="https://example.com/x"))
      expect(response.body).not_to include("[LINK CENSORED BY GOVCORP]")
    end

    it "renders :slug: emotes as images and ships the picker payload on the composer" do
      create(:emote, slug: "wave")
      create(:emote, :disabled, slug: "hidden_one")
      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "o/ :wave: :nope:")
      log_in!

      get "/uplink"

      expect(response.body).to include('class="emote"')
      expect(response.body).to include('alt=":wave:"')
      expect(response.body).to include(":nope:") # unknown tokens stay literal
      expect(response.body).to include('data-controller="packet-form emote-picker"')
      expect(response.body).to include("&quot;slug&quot;:&quot;wave&quot;")
      expect(response.body).to include("&quot;width&quot;:28,&quot;height&quot;:28") # picker previews get the same box
      expect(response.body).not_to include("hidden_one") # disabled: not in the payload
      expect(response.body).to include('data-emote-picker-target="menu"')
    end
  end

  describe "GET /uplink/popout" do
    let!(:live_channel) { create(:chat_channel, :livestream_only, slug: "live", name: "#live") }

    it "is public, slim-chromed, and shows the offline state when nothing is live" do
      get "/uplink/popout"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("uplink-popout")
      expect(response.body).to include("#live is only available during livestreams.")
      expect(response.body).not_to include("header-nav") # no site nav in the popout layout
      expect(response.body).not_to include("player-bar")
    end

    it "renders the live channel log and login prompt during a stream" do
      create(:hackr_stream, artist: create(:artist), is_live: true,
        live_url: "https://www.youtube.com/watch?v=abc123xyz00")
      create(:chat_message, chat_channel: live_channel, grid_hackr: other, content: "Live wire packet")

      get "/uplink/popout"

      expect(response.body).to include("Live wire packet")
      expect(response.body).to include("to transmit packets") # anonymous login prompt
      expect(response.body).to include("turbo-cable-stream-source")
    end

    it "keeps the panel single-line and shell-free (as does the home dock)" do
      create(:hackr_stream, artist: create(:artist), is_live: true,
        live_url: "https://www.youtube.com/watch?v=abc123xyz00")
      log_in!

      get "/uplink/popout"
      expect(response.body).to include('<input type="text" name="content"')
      expect(response.body).not_to include("<textarea")
      expect(response.body).not_to include("uplink-shell")
      expect(response.body).not_to include("packet-input-emote")
      expect(response.body).not_to include("data-packet-log-group-value")
      expect(response.body).not_to include("uplink-log-top") # no scrollback sentinel
      expect(response.body).to include("channel-tab channel-tab--active") # tabs stay

      get "/"
      expect(response.body).to include("live-side-panel--uplink")
      expect(response.body).to include('<input type="text" name="content"')
      expect(response.body).not_to include("uplink-shell")
    end
  end

  describe "GET /uplink/log" do
    it "returns the log frame for viewable channels" do
      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Recovered packet")
      log_in!

      get "/uplink/log", params: {channel: "ambient"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="uplink-log-frame"')
      expect(response.body).to include("Recovered packet")
    end

    it "404s on unknown channels" do
      get "/uplink/log", params: {channel: "nope"}

      expect(response).to have_http_status(:not_found)
    end

    it "403s when the viewer cannot see the channel" do
      get "/uplink/log", params: {channel: "ambient"} # anonymous, non-livestream

      expect(response).to have_http_status(:forbidden)

      get "/uplink/log", params: {channel: "ambient", before: 1}
      expect(response).to have_http_status(:forbidden)
    end

    it "reloads the frame in shell mode with shell=1 (grouping + scrollback sentinel), plain otherwise" do
      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Recovered packet")
      log_in!

      get "/uplink/log", params: {channel: "ambient", shell: 1}
      expect(response.body).to include('id="uplink-log-frame"')
      expect(response.body).to include('data-packet-log-group-value="true"')
      expect(response.body).to include('class="uplink-log-top" data-packet-log-target="top" data-more="false"')
      expect(response.body).to include('data-src="/uplink/log?channel=ambient"')

      get "/uplink/log", params: {channel: "ambient"}
      expect(response.body).to include('id="uplink-log-frame"')
      expect(response.body).not_to include("data-packet-log-group-value")
      expect(response.body).not_to include("uplink-log-top")
    end

    it "pages older packets before an id: packets only, chronological, capped at 40, dropped excluded, end marker on the last page" do
      now = Time.current
      ChatMessage.insert_all((1..45).map { |i|
        {chat_channel_id: channel.id, grid_hackr_id: other.id, content: "archive packet #{i}",
         dropped: i == 30, created_at: now - (45 - i).seconds, updated_at: now}
      })
      ids = channel.chat_messages.order(:id).pluck(:id)
      log_in!

      get "/uplink/log", params: {channel: "ambient", before: ids.last}

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).not_to include("uplink-log-frame")
      expect(body).not_to include("uplink-log-top")
      expect(body).not_to include("No packets yet")
      expect(body.scan(/archive packet (\d+)</).flatten.map(&:to_i)).to eq((4..44).to_a - [30]) # 40 newest below the cursor, oldest first
      expect(body).not_to include("data-log-end") # three remain
      expect(body).to include(%(data-author-key="h#{other.id}")) # grouping attrs ride along

      get "/uplink/log", params: {channel: "ambient", before: ids[3]}
      expect(response.body.scan(/archive packet (\d+)</).flatten.map(&:to_i)).to eq([1, 2, 3])
      expect(response.body).to include("<template data-log-end></template>")

      get "/uplink/log", params: {channel: "ambient", before: ids.first}
      expect(response.body).to include("<template data-log-end></template>")
      expect(response.body).not_to include("archive packet")
    end

    it "400s on a non-positive before cursor" do
      log_in!

      get "/uplink/log", params: {channel: "ambient", before: "abc"}

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /uplink/packets" do
    it "requires login" do
      post "/uplink/packets", params: {channel_slug: "ambient", content: "hi"}

      expect(response).to have_http_status(:redirect)
    end

    it "creates the packet and appends it in the turbo_stream response" do
      log_in!

      expect {
        post "/uplink/packets", params: {channel_slug: "ambient", content: "Fresh transmission"},
          headers: turbo_stream_headers
      }.to change(ChatMessage, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('action="append" target="uplink-log"')
      expect(response.body).to include("Fresh transmission")
      expect(response.body).to include('action="replace" target="uplink-form-error"')
      expect(ChatMessage.last.grid_hackr).to eq(hackr)
      expect(ChatMessage.last.hackr_stream).to be_nil
    end

    it "normalizes textarea newlines: CRLF to LF, blank-line runs capped, edges trimmed" do
      log_in!

      post "/uplink/packets", params: {channel_slug: "ambient", content: "  one\r\n\r\n\r\n\r\ntwo\r\nthree  "},
        headers: turbo_stream_headers

      expect(ChatMessage.last.content).to eq("one\n\ntwo\nthree")
    end

    it "stores the raw :slug: token and renders the image only in the HTML" do
      create(:emote, slug: "wave")
      log_in!

      post "/uplink/packets", params: {channel_slug: "ambient", content: "o/ :wave:"},
        headers: turbo_stream_headers

      expect(ChatMessage.last.content).to eq("o/ :wave:") # relay/synthia/terminal see plain text
      expect(response.body).to include('alt=":wave:"')
      expect(response.body).to include('src="/rails/active_storage/representations/redirect/')
      expect(response.body).to include('width="28" height="28"') # from the analyzed 56x56 fixture
    end

    it "attaches the live stream on livestream channels" do
      live_channel = create(:chat_channel, :livestream_only, slug: "live")
      stream = create(:hackr_stream, artist: create(:artist), is_live: true,
        live_url: "https://www.youtube.com/watch?v=abc123xyz00")
      log_in!

      post "/uplink/packets", params: {channel_slug: "live", content: "On air"}, headers: turbo_stream_headers

      expect(ChatMessage.last.chat_channel).to eq(live_channel)
      expect(ChatMessage.last.hackr_stream).to eq(stream)
    end

    it "checks the uplink_packets_count achievement" do
      log_in!
      expect_any_instance_of(Grid::AchievementChecker).to receive(:check).with("uplink_packets_count")

      post "/uplink/packets", params: {channel_slug: "ambient", content: "Counted"}, headers: turbo_stream_headers
    end

    it "renders validation errors into the form-error slot" do
      log_in!

      post "/uplink/packets", params: {channel_slug: "ambient", content: ""}, headers: turbo_stream_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('action="replace" target="uplink-form-error"')
      expect(response.body).to include("packet-input-error")
    end

    it "blocks squelched hackrs" do
      create(:user_punishment, :squelch, grid_hackr: hackr)
      log_in!

      post "/uplink/packets", params: {channel_slug: "ambient", content: "hi"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("You have been squelched.")
      expect(ChatMessage.count).to eq(0)
    end

    it "blocks blackedout hackrs" do
      create(:user_punishment, :blackout, grid_hackr: hackr)
      log_in!

      post "/uplink/packets", params: {channel_slug: "ambient", content: "hi"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("You have been blackedout from Uplink.")
    end

    it "blocks channels above the viewer's role" do
      create(:chat_channel, :operator_only, slug: "ops")
      log_in!

      post "/uplink/packets", params: {channel_slug: "ops", content: "hi"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("You cannot access this channel.")
    end

    it "enforces slow mode with a wait_seconds cooldown attribute" do
      slow = create(:chat_channel, :slow_mode, slug: "slow")
      create(:chat_message, chat_channel: slow, grid_hackr: hackr, created_at: 5.seconds.ago)
      log_in!

      post "/uplink/packets", params: {channel_slug: "slow", content: "too fast"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Slow mode active.")
      expect(response.body).to match(/data-wait-seconds="\d+"/)
    end

    it "404s on unknown channels" do
      log_in!

      post "/uplink/packets", params: {channel_slug: "nope", content: "hi"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /uplink/packets/:id/drop" do
    let!(:packet) { create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Target packet") }

    it "lets the author drop their own packet" do
      log_in!(other)

      post "/uplink/packets/#{packet.id}/drop", headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="replace" target="chat_message_#{packet.id}"))
      expect(response.body).to include("[PACKET DROPPED]")
      expect(packet.reload.dropped).to be(true)
      expect(ModerationLog.last).to have_attributes(action: "drop_packet", actor: other, target: other)
    end

    it "lets operators drop anyone's packet" do
      log_in!(operator)

      post "/uplink/packets/#{packet.id}/drop", headers: turbo_stream_headers

      expect(packet.reload.dropped).to be(true)
      expect(ModerationLog.last).to have_attributes(action: "drop_packet", actor: operator, target: other)
    end

    it "forbids operatives dropping someone else's packet" do
      log_in!(hackr)

      post "/uplink/packets/#{packet.id}/drop", headers: turbo_stream_headers

      expect(response).to have_http_status(:forbidden)
      expect(packet.reload.dropped).to be(false)
    end

    it "404s on unknown packets" do
      log_in!

      post "/uplink/packets/0/drop", headers: turbo_stream_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /uplink/packets/:id/restore" do
    let!(:packet) { create(:chat_message, :dropped, chat_channel: channel, grid_hackr: other, content: "Comeback packet") }

    it "lets operators restore a dropped packet" do
      log_in!(operator)

      post "/uplink/packets/#{packet.id}/restore", headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Comeback packet")
      expect(packet.reload.dropped).to be(false)
      expect(ModerationLog.last).to have_attributes(action: "restore_packet", actor: operator, target: other)
    end

    it "forbids non-operators — including the author" do
      log_in!(other)

      post "/uplink/packets/#{packet.id}/restore", headers: turbo_stream_headers

      expect(response).to have_http_status(:forbidden)
      expect(packet.reload.dropped).to be(true)
    end
  end
end
