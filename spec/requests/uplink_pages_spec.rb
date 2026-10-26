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
      expect(body).to include('class="uplink-shell" data-controller="uplink uplink-shell popover"')
      expect(body).to include("hackr.tv NODE")
      expect(body).to include('data-uplink-shell-channel-value="ambient"')
      expect(body).to include('data-channel="ops"')
      expect(body).to include('<span class="uplink-channel-badge" hidden="hidden" title="Unread packets" data-count="0"></span>')
      expect(body.index("BROADCAST")).to be < body.index("COMMS") # category order follows position
      expect(body.index(">#ambient<")).to be < body.index(">#ops<")
      expect(body).to include('<h2 class="uplink-chanhead-name">#ambient</h2>')
      expect(body).to include("Always-on ambient comms.") # description as the topic
      expect(body).not_to include("chrome-content") # no default chrome around the shell
      expect(body).to include(%(@#{hackr.hackr_alias})) # user panel
    end

    it "counts unread packets per sidebar row: caught up on first sight, then a badge per channel (99+ capped, --mention when one @mentions you), never on the channel on screen, with a bump slot + stream per counted channel" do
      trace = create(:chat_channel, slug: "trace", name: "#trace")
      ops = create(:chat_channel, slug: "ops", name: "#ops")
      create(:chat_channel, :operator_only, slug: "secret", name: "#secret")
      create(:chat_message, chat_channel: trace, grid_hackr: other, content: "before you ever looked")
      log_in!

      get "/uplink"

      expect(response).to have_http_status(:ok)
      expect(UplinkChannelRead.where(grid_hackr: hackr).pluck(:chat_channel_id)).to contain_exactly(channel.id, trace.id, ops.id) # viewable channels only
      expect(response.body).not_to include("uplink-channel--unread") # first sight: caught up, nothing counts
      expect(response.body).to include('data-uplink-shell-ack-url-value="/uplink/reads"')

      create(:chat_message, chat_channel: trace, grid_hackr: other, content: "one")
      create(:chat_message, chat_channel: trace, grid_hackr: other, content: "two, @#{hackr.hackr_alias}")
      create(:chat_message, :dropped, chat_channel: trace, grid_hackr: other, content: "dropped: not counted")
      now = Time.current
      ChatMessage.insert_all(Array.new(100) { |i| {chat_channel_id: ops.id, grid_hackr_id: other.id, content: "flood #{i}", created_at: now, updated_at: now} })

      get "/uplink"

      body = response.body
      row = ->(slug) { body[/<a [^>]*data-channel="#{slug}"[^>]*>.*?<\/a>/m] }
      expect(row.call("trace")).to include("uplink-channel uplink-channel--unread uplink-channel--mention")
      expect(row.call("trace")).to include('<span class="uplink-channel-badge" title="Unread packets" data-count="2">2</span>')
      expect(row.call("ops")).to include("uplink-channel--unread")
      expect(row.call("ops")).not_to include("uplink-channel--mention")
      expect(row.call("ops")).to include('data-count="100">99+</span>')
      expect(row.call("ambient")).to include("uplink-channel--active")
      expect(row.call("ambient")).not_to include("uplink-channel--unread")
      expect(row.call("ambient")).to include('hidden="hidden" title="Unread packets" data-count="0"></span>')
      bumps = body[/<div class="uplink-bumps" hidden data-uplink-shell-target="bumps">.*?<\/div>/m]
      expect(bumps.scan("<turbo-cable-stream-source").size).to eq(2) # trace + ops: never the channel on screen, never a channel outside clearance
      expect(bumps).to include('<span id="uplink-bump-trace" data-channel="trace"></span>')
      expect(bumps).to include('<span id="uplink-bump-ops" data-channel="ops"></span>')
      expect(bumps).not_to include("uplink-bump-ambient")
      expect(bumps).not_to include("uplink-bump-secret")
      expect(body).not_to include("uplink-bump-secret")

      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "lands in #ambient after you looked")
      get "/uplink", params: {channel: "trace"}

      body = response.body
      expect(UplinkChannelRead.find_by!(grid_hackr: hackr, chat_channel: trace).last_read_message_id).to eq(ChatMessage.where(chat_channel: trace).maximum(:id)) # the visit marks it read (dropped ids count as seen)
      expect(body[/<a [^>]*data-channel="trace"[^>]*>.*?<\/a>/m]).to include('data-count="0"></span>')
      expect(body[/<a [^>]*data-channel="ambient"[^>]*>.*?<\/a>/m]).to include('data-count="1">1</span>')
      expect(body[/<a [^>]*data-channel="ops"[^>]*>.*?<\/a>/m]).to include('data-count="100">99+</span>') # untouched
    end

    it "draws the NEW PACKETS separator before the first packet above the viewer's previous mark — never on first sight, never once the visit moved the mark, never on a reload" do
      trace = create(:chat_channel, slug: "trace", name: "#trace")
      seen = create(:chat_message, chat_channel: trace, grid_hackr: other, content: "seen before")
      log_in!

      get "/uplink", params: {channel: "trace"} # first sight: caught up, no separator, no mark on the sentinel url
      expect(response.body).not_to include("uplink-unseen")
      expect(response.body).to include(%(data-src="/uplink/log?channel=trace"></div>))

      one = create(:chat_message, chat_channel: trace, grid_hackr: other, content: "fresh one")
      two = create(:chat_message, chat_channel: trace, grid_hackr: other, content: "fresh two")
      get "/uplink", params: {channel: "trace"}

      body = response.body
      separator = '<div class="uplink-unseen" role="separator" aria-label="New packets" data-packet-log-target="unseen">// NEW PACKETS //</div>'
      expect(body.scan("uplink-unseen").size).to eq(1)
      expect(body).to include(separator)
      expect(body.index("chat_message_#{seen.id}")).to be < body.index(separator)
      expect(body.index(separator)).to be < body.index("chat_message_#{one.id}")
      expect(body.index("chat_message_#{one.id}")).to be < body.index("chat_message_#{two.id}")
      expect(body).to include(%(data-src="/uplink/log?channel=trace&amp;unseen_from=#{seen.id}"></div>)) # the mark rides the sentinel url

      get "/uplink", params: {channel: "trace"} # the visit moved the mark: nothing above it now
      expect(response.body).not_to include("uplink-unseen")

      get "/uplink/log", params: {channel: "trace", shell: 1} # reconnect reload: no mark, no separator
      expect(response.body).not_to include("uplink-unseen")
    end

    it "opens at the separator when up to 100 packets are unseen (5 seen for context, then every unseen one), and for a flood beyond that leaves the line to the scrollback page that holds the boundary" do
      trace = create(:chat_channel, slug: "trace", name: "#trace")
      now = Time.current
      rows = ->(n, label) { ChatMessage.insert_all(Array.new(n) { |i| {chat_channel_id: trace.id, grid_hackr_id: other.id, content: "#{label} #{i}", created_at: now, updated_at: now} }) }
      rows.call(8, "old")
      log_in!
      get "/uplink", params: {channel: "trace"} # caught up at old 7
      mark = ChatMessage.where(chat_channel: trace).maximum(:id)

      rows.call(30, "fresh")
      get "/uplink", params: {channel: "trace"}

      body = response.body
      ids = body.scan(/id="chat_message_(\d+)"/).flatten.map(&:to_i)
      expect(ids.size).to eq(35) # 5 context + 30 unseen, not the newest 20
      expect(ids).to eq(ids.sort)
      expect(ids.first).to eq(mark - 4)
      expect(ids.last).to eq(ChatMessage.where(chat_channel: trace).maximum(:id))
      expect(body.scan("uplink-unseen").size).to eq(1)
      expect(body.index("uplink-unseen")).to be > body.index("chat_message_#{mark}")
      expect(body.index("uplink-unseen")).to be < body.index("chat_message_#{mark + 1}")
      expect(body).to include('class="uplink-log-top" data-packet-log-target="top" data-more="true"') # old 0..2 are still above

      rows.call(120, "flood") # beyond UNSEEN_PACKETS: newest 20, no line on the page
      flood_mark = ChatMessage.where(chat_channel: trace).maximum(:id) - 120
      get "/uplink", params: {channel: "trace"} # the previous visit left the mark at fresh 29
      body = response.body
      expect(body.scan(%(id="chat_message_)).size).to eq(20)
      expect(body).not_to include("uplink-unseen")
      expect(body).to include(%(data-src="/uplink/log?channel=trace&amp;unseen_from=#{flood_mark}"></div>))

      # Scroll back page by page (40 each): fully unseen pages carry no line; the page that straddles the mark draws it, once.
      first = body.scan(/id="chat_message_(\d+)"/).flatten.map(&:to_i).min
      pages = []
      4.times do
        get "/uplink/log", params: {channel: "trace", before: first, unseen_from: flood_mark}
        pages << response.body
        first = response.body.scan(/id="chat_message_(\d+)"/).flatten.map(&:to_i).min
        break if response.body.include?("chat_message_#{flood_mark}\"")
      end
      expect(pages.size).to eq(3) # flood 60..99, flood 20..59, then flood 0..19 + fresh 10..29
      expect(pages[0]).not_to include("uplink-unseen")
      expect(pages[1]).not_to include("uplink-unseen")
      body = pages[2]
      expect(body.scan("uplink-unseen").size).to eq(1)
      expect(body).to include('<div class="uplink-unseen" role="separator" aria-label="New packets">// NEW PACKETS //</div>') # no scroll target on a spliced page
      expect(body.index("uplink-unseen")).to be > body.index("chat_message_#{flood_mark}\"")
      expect(body.index("uplink-unseen")).to be < body.index("chat_message_#{flood_mark + 1}\"")

      get "/uplink/log", params: {channel: "trace", before: first} # no mark: never a line
      expect(response.body).not_to include("uplink-unseen")
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
      log_in!(other) # a fresh viewer gets the newest page (this hackr, with 21 unseen, would get the whole run behind the NEW PACKETS line)
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

    it "renders replies: quote line + data-reply-to, bridged and dropped parents, the hover reply control, the composer's reply bar" do
      parent = create(:chat_message, chat_channel: channel, grid_hackr: other, content: "  the   original   transmission " + ("x" * 90))
      reply = create(:chat_message, chat_channel: channel, grid_hackr: hackr, reply_to: parent, content: "quoting you")
      bridge = create(:grid_hackr, hackr_alias: "svc_bridge", service_account: true)
      bridged = create(:chat_message, chat_channel: channel, grid_hackr: bridge, source: "TTV", content: "[Twitch] viewer42: hi from twitch")
      to_bridged = create(:chat_message, chat_channel: channel, grid_hackr: hackr, reply_to: bridged, content: "hey viewer")
      gone = create(:chat_message, :dropped, chat_channel: channel, grid_hackr: other, content: "secret")
      to_gone = create(:chat_message, chat_channel: channel, grid_hackr: hackr, reply_to: gone, content: "too late")
      log_in!

      get "/uplink"

      body = response.body
      expect(body).to include(%(id="chat_message_#{reply.id}"))
      expect(body).to match(%r{id="chat_message_#{reply.id}"[^>]*class="packet packet--reply"[^>]*data-reply-to="#{parent.id}"}m)
      expect(body).to include(%(<span class="packet-reply-author packet-reply-author--operative">@#{other.hackr_alias}</span>))
      expect(body).to include(%(<span class="packet-reply-excerpt">the original transmission #{"x" * 51}...</span>)) # squished, 80 chars
      expect(body).to include('data-action="click->packet#jumpToParent"')
      expect(body).to include(%(<span class="packet-reply-author packet-reply-author--bridged">TTV viewer42</span>))
      expect(body).to include(%(<span class="packet-reply-excerpt">hi from twitch</span>))
      expect(body).to match(%r{id="chat_message_#{to_gone.id}".*?<span class="packet-reply-excerpt">\[PACKET DROPPED\]</span>}m)
      expect(body).not_to include("secret")
      expect(body).not_to match(%r{id="chat_message_#{parent.id}"[^>]*data-reply-to}) # plain packets carry none
      expect(body).to match(%r{id="chat_message_#{to_bridged.id}"[^>]*data-reply-to="#{bridged.id}"})

      # Hover control on every live packet (not the dropped one), carrying the sender label
      expect(body).to include(%(data-action="click->packet#reply" data-reply-sender="@#{other.hackr_alias}"))
      expect(body).to include(%(data-reply-sender="TTV viewer42"))
      expect(body).not_to match(%r{id="chat_message_#{gone.id}".*?packet-reply-button.*?id="chat_message_#{to_gone.id}"}m)

      # Composer: hidden reply_to_id + reply bar, listening on document
      expect(body).to include('data-action="packet:reply@document->packet-form#reply"')
      expect(body).to include('name="reply_to_id"')
      expect(body).to include('class="packet-reply-bar" hidden data-packet-form-target="replyBar"')
      expect(body).to include('data-action="click->packet-form#cancelReply"')
    end

    it "mounts the operative record popover: controller + document actions on the shell, the hidden _top frame in the pane, author links carrying the profile url" do
      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "who am I")
      log_in!

      get "/uplink"

      body = response.body
      expect(body).to include('data-controller="uplink uplink-shell popover"')
      expect(body).to include("turbo:frame-load->popover#loaded mousedown@document->popover#outside keydown@document->popover#keydown")
      frame = body[/<turbo-frame[^>]*id="uplink-popover"[^>]*>/]
      expect(frame).to include('target="_top"')
      expect(frame).to include("hidden")
      expect(frame).to include('class="uplink-popover-frame"')
      expect(frame).to include('data-popover-target="frame"')
      expect(body).to match(%r{<div class="uplink-main"[^>]*>.*?#{Regexp.escape(frame)}.*?</div>\s*<aside class="uplink-members-pane"}m) # inside the pane, not a grid child
      expect(body).to include(%(href="/wire/#{other.hackr_alias}" data-action="click->popover#open"))
      expect(body).to include(%(data-popover-url-param="/uplink/profiles/#{other.hackr_alias.downcase}")) # canonical lowercase: mixed case 301s
    end

    it "mounts the operator menu: the second popover frame as a grid child, hidden [...] triggers on native packets and roster rows carrying the menu url (callsign token only, lowercase)" do
      create(:chat_message, chat_channel: channel, grid_hackr: other, content: "mod me")
      create(:chat_message, chat_channel: channel, grid_hackr: other, source: "TTV", content: "[Twitch] viewer: bridged")
      lurker = create(:grid_hackr)
      GridUplinkPresence.touch!(lurker, channel)
      log_in!(operator)

      get "/uplink"

      body = response.body
      expect(body).to include("keydown@document->popover#keydown turbo:submit-end->popover#submitted")
      frame = body[/<turbo-frame[^>]*id="uplink-modmenu"[^>]*>/]
      expect(frame).to include('target="_top"')
      expect(frame).to include("hidden")
      expect(frame).to include('class="uplink-modmenu-frame"')
      expect(frame).to include('data-popover-target="frame"')
      expect(body).to match(%r{<div class="uplink-backdrop"[^\n]*></div>\s*#{Regexp.escape(frame)}</turbo-frame>\s*</div>}m) # a grid child, after the backdrop

      packet = ChatMessage.find_by(content: "mod me")
      expect(body).to include(%(data-packet-author-role-value="operative"))
      triggers = body.scan(/<button type="button" class="packet-action-button packet-mod-button".*?<\/button>/m) # ([^>]* would stop at the -> in data-action)
      expect(triggers.size).to eq(1) # the bridged packet (service account author) gets none
      expect(triggers.first).to include("hidden") # revealed client-side by the packet controller
      expect(triggers.first).to include('data-packet-target="modControl"')
      expect(triggers.first).to include(%(data-action="click->popover#open"))
      expect(triggers.first).to include(%(data-popover-url-param="/uplink/packets/#{packet.id}/menu"))
      expect(triggers.first).to include('data-popover-frame-param="uplink-modmenu"')
      expect(triggers.first).to include('data-popover-align-param="end"')

      roster = body[/<div id="uplink-members".*?<\/div>/m]
      token = Uplink::Callsign.token(lurker.id)
      row = roster[/<li class="uplink-member uplink-member--operative" data-callsign="#{token}"[^>]*>.*?<\/li>/m]
      expect(row).to include('data-role="operative"')
      expect(row).to include('class="uplink-member-mod"')
      expect(row).to include("hidden")
      expect(row).to include(%(data-popover-url-param="/uplink/operatives/#{token.downcase}/menu"))
      expect(row).to include('data-popover-frame-param="uplink-modmenu" data-popover-align-param="end">...</button>')
      expect(roster).not_to include(lurker.hackr_alias)
      expect(roster.scan(%r{/uplink/[^"]*})).to all(match(%r{\A/uplink/operatives/[0-9a-f]{6}/menu\z})) # every roster url is token-addressed: no /hackrs/:id oracle
      expect(roster).not_to match(%r{hackr[-_]id|[="/]#{lurker.id}["/]}) # the id rides no attribute value or path segment (a bare include would match any digit in a token or count)
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
    it "carries no unread badges, bump slots or read-ack url (the dock neither: both render _panel)" do
      get "/uplink/popout"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("uplink-channel-badge")
      expect(response.body).not_to include("uplink-bumps")
      expect(response.body).not_to include("uplink-shell-ack-url")
      expect(response.body).not_to include("uplink-unseen")
      expect(UplinkChannelRead.count).to eq(0)
    end

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
      create(:chat_message, chat_channel: live_channel, grid_hackr: other, content: "Popout packet")
      log_in!

      get "/uplink/popout"
      expect(response.body).to include('<input type="text" name="content"')
      expect(response.body).not_to include("<textarea")
      expect(response.body).not_to include("uplink-shell")
      expect(response.body).not_to include("packet-input-emote")
      expect(response.body).not_to include("data-packet-log-group-value")
      expect(response.body).not_to include("uplink-log-top") # no scrollback sentinel
      expect(response.body).not_to include("packet-reply-bar") # no reply composer (the packet's reply control is CSS-hidden)
      expect(response.body).not_to include('name="reply_to_id"')
      expect(response.body).not_to include('id="uplink-popover"') # no record popover frame / controller …
      expect(response.body).not_to include("popover#outside")
      expect(response.body).to include("click->popover#open") # … so the author link's action is inert and it visits the WIRE profile
      expect(response.body).not_to include('id="uplink-modmenu"') # no operator menu frame either; the packet's […] stays CSS-hidden
      expect(response.body).to include('data-popover-frame-param="uplink-modmenu"')
      expect(response.body).not_to include("uplink-chanhead-pins") # no pins button, count or panel frame; the packet's ◆ form is CSS-hidden
      expect(response.body).not_to include('id="uplink-pins"')
      expect(response.body).to include("uplink-pin-form")
      expect(response.body).not_to include('id="uplink-reactmenu"') # no reaction picker frame; the packet's :) is CSS-hidden, the chips still toggle …
      expect(response.body).to include("packet-react-button", "packet-reactions")
      expect(response.body).to include(%(<meta name="uplink-callsign" content="#{Uplink::Callsign.token(hackr.id)}">)) # … and the reactions controller marks the viewer's own here too
      expect(response.body).to include("channel-tab channel-tab--active") # tabs stay

      get "/"
      expect(response.body).to include("live-side-panel--uplink")
      expect(response.body).to include(%(<meta name="uplink-callsign" content="#{Uplink::Callsign.token(hackr.id)}">))
      expect(response.body).not_to include('id="uplink-reactmenu"')
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

  describe "GET /uplink/profiles/:alias" do
    def frame_headers
      {"Turbo-Frame" => "uplink-popover"}
    end

    it "requires login" do
      get "/uplink/profiles/#{other.hackr_alias.downcase}", headers: frame_headers

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/grid/login")
    end

    it "renders the operative record card into the popover frame: alias + role in shell colors, clearance, member since, online now, bio with mention links, stat tiles, WIRE link" do
      other.update!(bio: "Grid runner. Ask @#{hackr.hackr_alias} about the breach.", stats: {"clearance" => 7}, last_activity_at: 2.minutes.ago)
      create_list(:chat_message, 2, chat_channel: channel, grid_hackr: other)
      create(:pulse, grid_hackr: other, echo_count: 3)
      log_in!

      get "/uplink/profiles/#{other.hackr_alias.downcase}", headers: frame_headers

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('<turbo-frame id="uplink-popover">')
      expect(body).not_to include("header-nav") # frame layout, no site chrome
      expect(body).to include(%(<div class="uplink-popover" role="dialog" aria-label="Operative record: @#{other.hackr_alias}" tabindex="-1">))
      expect(body).to include(%(<span class="uplink-popover-alias uplink-popover-alias--operative">@#{other.hackr_alias}</span>))
      expect(body).to include('<span class="uplink-popover-badge uplink-popover-badge--operative">OPERATIVE</span>')
      expect(body).to include('<span class="uplink-popover-cl">CL7</span>')
      expect(body).to include('data-action="click->popover#dismiss"')
      expect(body).to include("MEMBER SINCE #{other.created_at.strftime("%b %-d, %Y").upcase}")
      expect(body).to include('<span class="uplink-popover-active uplink-popover-active--online">● ONLINE NOW</span>')
      expect(body).to include(%(<p class="uplink-popover-bio">#{BioTextRenderer.render(other.bio)}</p>)) # @mention → link, as on the WIRE
      expect(body).to include(%(class="bio-mention"))
      expect(body).to include('<span class="uplink-popover-stat-value">2</span><span class="uplink-popover-stat-label">PACKETS</span>')
      expect(body).to include('<span class="uplink-popover-stat-value">1</span><span class="uplink-popover-stat-label">WIRE PULSES</span>')
      expect(body).to include('<span class="uplink-popover-stat-value">3</span><span class="uplink-popover-stat-label">ECHOES</span>')
      expect(body).to include('<span class="uplink-popover-stat-value">0</span><span class="uplink-popover-stat-label">ACHIEVEMENTS</span>')
      expect(body).to include(%(<a class="uplink-popover-link" data-turbo-frame="_top" href="/wire/#{other.hackr_alias.downcase}">[WIRE PROFILE]</a>))
    end

    it "looks the alias up case-insensitively (the alias is stored mixed-case, the url is lowercase); operators get their color, no bio reads as such, last active in days" do
      operator.update!(bio: nil, last_activity_at: 3.days.ago)
      expect(operator.hackr_alias).not_to eq(operator.hackr_alias.downcase)
      log_in!

      get "/uplink/profiles/#{operator.hackr_alias.downcase}", headers: frame_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(uplink-popover-alias--operator">@#{operator.hackr_alias}</span>))
      expect(response.body).to include('uplink-popover-badge--operator">OPERATOR</span>')
      expect(response.body).to include('<p class="uplink-popover-bio uplink-popover-bio--empty">No bio on record.</p>')
      expect(response.body).to include('<span class="uplink-popover-active">● ACTIVE 3D AGO</span>')
      expect(response.body).not_to include("uplink-popover-active--online")
    end

    it "404s with a NO RECORD card on unknown aliases" do
      log_in!

      get "/uplink/profiles/nobody_here", headers: frame_headers

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('<turbo-frame id="uplink-popover">')
      expect(response.body).to include("// NO RECORD //")
      expect(response.body).to include("@nobody_here is not on this NODE.")
      expect(response.body).to include('data-action="click->popover#dismiss"')
    end

    it "sends a non-frame request to the WIRE profile instead" do
      log_in!

      get "/uplink/profiles/#{other.hackr_alias.downcase}"

      expect(response).to redirect_to("/wire/#{other.hackr_alias.downcase}")
    end
  end

  describe "operator menu (GET …/menu, POST …/squelch | blackout | lift)" do
    let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
    let!(:packet) { create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Menu target") }
    let(:token) { Uplink::Callsign.token(other.id).downcase }

    def frame_headers
      {"Turbo-Frame" => "uplink-modmenu"}
    end

    def menu_body
      response.body[/<turbo-frame id="uplink-modmenu">.*<\/turbo-frame>/m]
    end

    it "requires login, and an operator" do
      get "/uplink/packets/#{packet.id}/menu", headers: frame_headers
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/grid/login")

      log_in!(hackr)
      get "/uplink/packets/#{packet.id}/menu", headers: frame_headers
      expect(response).to have_http_status(:forbidden)
      post "/uplink/packets/#{packet.id}/squelch", params: {duration_minutes: 10}, headers: turbo_stream_headers
      expect(response).to have_http_status(:forbidden)
      post "/uplink/operatives/#{token}/blackout", headers: turbo_stream_headers
      expect(response).to have_http_status(:forbidden)
      expect(UserPunishment.count).to eq(0)
    end

    it "renders a packet's menu into the frame: the author's alias + role color, drop, three squelch durations, blackout, no lift, a reason field guarded against Enter" do
      log_in!(operator)

      get "/uplink/packets/#{packet.id}/menu", headers: frame_headers

      expect(response).to have_http_status(:ok)
      menu = menu_body
      expect(menu).to include('class="uplink-modmenu" role="dialog"')
      expect(menu).to include(%(aria-label="Moderate @#{other.hackr_alias}"))
      expect(menu).to include(%(<span class="uplink-modmenu-target uplink-modmenu-target--operative">@#{other.hackr_alias}</span>))
      expect(menu).to include('data-action="click->popover#dismiss"')
      expect(menu).to include(%(<form class="uplink-modmenu-form" data-turbo-frame="_top" action="/uplink/packets/#{packet.id}/squelch" accept-charset="UTF-8" method="post">))
      expect(menu).to match(/<button type="submit" class="uplink-modmenu-guard" disabled hidden[^>]*><\/button>\s*<input type="text" name="reason"/)
      expect(menu).to include(%(formaction="/uplink/packets/#{packet.id}/drop">DROP PACKET</button>))
      expect(menu).not_to include("RESTORE PACKET")
      %w[10 60 1440].zip(%w[10M 1H 24H]).each do |minutes, label|
        expect(menu).to include(%(formaction="/uplink/packets/#{packet.id}/squelch"\n              name="duration_minutes" value="#{minutes}">SQUELCH #{label}</button>))
      end
      expect(menu).to include(%(formaction="/uplink/packets/#{packet.id}/blackout">BLACKOUT</button>))
      expect(menu).not_to include("LIFT PUNISHMENT")
      expect(menu).not_to include("uplink-modmenu-status")
    end

    it "shows standing punishments with time left, hides the matching action, offers lift (plural when both), and restore for a dropped packet" do
      create(:user_punishment, :squelch, grid_hackr: other, issued_by: operator, expires_at: 9.minutes.from_now + 30.seconds)
      create(:user_punishment, :blackout, grid_hackr: other, issued_by: operator)
      create(:user_punishment, :squelch, :expired, grid_hackr: other, issued_by: operator) # history, not status
      packet.drop!
      log_in!(admin)

      get "/uplink/packets/#{packet.id}/menu", headers: frame_headers

      menu = menu_body
      expect(menu).to include('<p class="uplink-modmenu-status">SQUELCHED · 10M LEFT</p>')
      expect(menu).to include('<p class="uplink-modmenu-status">BLACKED OUT · PERMANENT</p>')
      expect(menu.scan("uplink-modmenu-status").size).to eq(2)
      expect(menu).to include(%(formaction="/uplink/packets/#{packet.id}/restore">RESTORE PACKET</button>))
      expect(menu).not_to include("SQUELCH 10M")
      expect(menu).not_to include(">BLACKOUT<")
      expect(menu).to include(%(formaction="/uplink/packets/#{packet.id}/lift">LIFT PUNISHMENTS</button>))
    end

    it "renders a callsign's menu from its presence row: the callsign only — never the alias — and no packet actions; a stale token gets the empty state (404)" do
      GridUplinkPresence.touch!(other, channel)
      log_in!(operator)

      get "/uplink/operatives/#{token}/menu", headers: frame_headers

      expect(response).to have_http_status(:ok)
      menu = menu_body
      expect(menu).to include(%(<span class="uplink-modmenu-target uplink-modmenu-target--operative">SIG-#{token.upcase}</span>))
      expect(menu).not_to include(other.hackr_alias)
      expect(menu).not_to include("/uplink/packets/")
      expect(menu).to include(%(formaction="/uplink/operatives/#{token}/squelch"))
      expect(menu).to include(%(formaction="/uplink/operatives/#{token}/blackout"))

      GridUplinkPresence.remove!(other, channel)
      get "/uplink/operatives/#{token}/menu", headers: frame_headers
      expect(response).to have_http_status(:not_found)
      expect(menu_body).to include("// NO JURISDICTION //")
      expect(menu_body).to include("SIG-#{token.upcase} is no longer connected.")
      expect(menu_body).not_to include("formaction")

      get "/uplink/operatives/ABCDEF/menu", headers: frame_headers # a fixed lettered token: the real one is all digits ~6% of the time and then has no case to redirect
      expect(response).to have_http_status(:moved_permanently) # LowercaseRedirect: hence lowercase tokens in every generated URL
      expect(response.headers["Location"]).to end_with("/uplink/operatives/abcdef/menu")
    end

    it "keeps peers, superiors, oneself and service accounts out of jurisdiction, for the menu (403 frame) and the actions (403 toast)" do
      peer = create(:grid_hackr, :operator)
      bot = create(:grid_hackr, service_account: true)
      own = create(:chat_message, chat_channel: channel, grid_hackr: operator, content: "mine")
      peer_packet = create(:chat_message, chat_channel: channel, grid_hackr: peer, content: "peer")
      admin_packet = create(:chat_message, chat_channel: channel, grid_hackr: admin, content: "root")
      bot_packet = create(:chat_message, chat_channel: channel, grid_hackr: bot, source: "TTV", content: "[Twitch] v: hi")
      log_in!(operator)

      [own, peer_packet, admin_packet, bot_packet].each do |target|
        get "/uplink/packets/#{target.id}/menu", headers: frame_headers
        expect(response).to have_http_status(:forbidden)
        expect(menu_body).to include("// NO JURISDICTION //")
        expect(menu_body).to include("@#{target.grid_hackr.hackr_alias} is outside your clearance.")

        post "/uplink/packets/#{target.id}/squelch", params: {duration_minutes: 10}, headers: turbo_stream_headers
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include(%(action="append" target="toast-region"))
        expect(response.body).to include("toast--moderation toast--moderation-error")
        expect(response.body).to include("is outside your clearance.")
      end
      expect(UserPunishment.count).to eq(0)

      log_in!(admin)
      get "/uplink/packets/#{peer_packet.id}/menu", headers: frame_headers
      expect(response).to have_http_status(:ok) # admins outrank operators
      expect(menu_body).to include("uplink-modmenu-target--operator")
      get "/uplink/packets/#{admin_packet.id}/menu", headers: frame_headers
      expect(response).to have_http_status(:forbidden) # not a fellow admin

      get "/uplink/packets/0/menu", headers: frame_headers
      expect(response).to have_http_status(:not_found)
      expect(menu_body).to include("That packet is gone.")

      get "/uplink/packets/#{packet.id}/menu"
      expect(response).to redirect_to("/uplink") # no frame to land in
    end

    it "squelches the packet's author for the chosen duration with the reason, logs it, and toasts the operator" do
      log_in!(operator)

      post "/uplink/packets/#{packet.id}/squelch", params: {duration_minutes: 60, reason: "spam"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%(action="append" target="toast-region"))
      expect(response.body).to include('class="toast toast--moderation"')
      expect(response.body).to include('data-controller="toast"')
      expect(response.body).to include(%(<div class="toast-title">@#{other.hackr_alias} squelched for 1h.</div>))
      punishment = UserPunishment.last
      expect(punishment).to have_attributes(grid_hackr: other, issued_by: operator, punishment_type: "squelch", reason: "spam")
      expect(punishment.expires_at).to be_within(5.seconds).of(60.minutes.from_now)
      expect(UserPunishment.squelched?(other)).to be(true)
      expect(ModerationLog.last).to have_attributes(action: "squelch", actor: operator, target: other, duration_minutes: 60, reason: "spam")

      post "/uplink/packets/#{packet.id}/squelch", params: {duration_minutes: 10}, headers: turbo_stream_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("toast--moderation-error")
      expect(response.body).to include("is already squelched.")
      expect(UserPunishment.count).to eq(1)

      post "/uplink/packets/#{packet.id}/blackout", params: {duration_minutes: 7}, headers: turbo_stream_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Pick a duration from the menu.")
      expect(UserPunishment.count).to eq(1)
    end

    it "blacks out permanently by default (a blank duration), through a callsign too, keeping the alias out of the toast" do
      GridUplinkPresence.touch!(other, channel)
      log_in!(admin)

      post "/uplink/operatives/#{token}/blackout", params: {duration_minutes: ""}, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SIG-#{token.upcase} blacked out permanently.")
      expect(response.body).not_to include(other.hackr_alias)
      expect(UserPunishment.last).to have_attributes(grid_hackr: other, issued_by: admin, punishment_type: "blackout", expires_at: nil, reason: nil)
      expect(ModerationLog.last).to have_attributes(action: "blackout", actor: admin, target: other, duration_minutes: nil)

      GridUplinkPresence.remove!(other, channel)
      post "/uplink/operatives/#{token}/lift", headers: turbo_stream_headers
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("SIG-#{token.upcase} is no longer connected.")
      expect(UserPunishment.blackedout?(other)).to be(true)
    end

    it "lifts every active punishment, logging each, and refuses when there is nothing to lift" do
      create(:user_punishment, :squelch, :temporary, grid_hackr: other, issued_by: operator)
      create(:user_punishment, :blackout, grid_hackr: other, issued_by: operator)
      expired = create(:user_punishment, :squelch, :expired, grid_hackr: other, issued_by: operator)
      log_in!(operator)

      post "/uplink/packets/#{packet.id}/lift", headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@#{other.hackr_alias} lifted: squelched + blacked out.")
      expect(UserPunishment.active_for(other)).to be_empty
      expect(UserPunishment.exists?(expired.id)).to be(true) # history stays
      expect(ModerationLog.where(actor: operator, target: other).pluck(:action)).to contain_exactly("unsquelch", "unblackout")

      post "/uplink/packets/#{packet.id}/lift", headers: turbo_stream_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("has no active punishment.")
    end

    it "falls back to a flash redirect for plain form posts" do
      log_in!(operator)

      post "/uplink/packets/#{packet.id}/squelch", params: {duration_minutes: 10}

      expect(response).to redirect_to("/uplink")
      expect(flash[:success]).to eq("@#{other.hackr_alias} squelched for 10m.")
      expect(UserPunishment.squelched?(other)).to be(true)
    end
  end

  describe "POST /uplink/reads (the shell's read ack)" do
    let!(:first) { create(:chat_message, chat_channel: channel, grid_hackr: other, content: "first") }
    let!(:second) { create(:chat_message, chat_channel: channel, grid_hackr: other, content: "second") }

    it "requires login" do
      post "/uplink/reads", params: {channel: "ambient", last_read_message_id: first.id}

      expect(response).to have_http_status(:redirect)
      expect(UplinkChannelRead.count).to eq(0)
    end

    it "raises the viewer's mark to that packet (204) and never lowers it" do
      log_in!

      post "/uplink/reads", params: {channel: "ambient", last_read_message_id: second.id}
      expect(response).to have_http_status(:no_content)
      expect(UplinkChannelRead.find_by!(grid_hackr: hackr, chat_channel: channel).last_read_message_id).to eq(second.id)

      post "/uplink/reads", params: {channel: "ambient", last_read_message_id: first.id} # a tab that fell behind
      expect(response).to have_http_status(:no_content)
      expect(UplinkChannelRead.find_by!(grid_hackr: hackr, chat_channel: channel).last_read_message_id).to eq(second.id)
      expect(UplinkChannelRead.count).to eq(1)
    end

    it "refuses an unknown channel (404), one outside the viewer's clearance (403) and a packet from elsewhere (422)" do
      create(:chat_channel, :operator_only, slug: "secret")
      elsewhere = create(:chat_message, chat_channel: create(:chat_channel, slug: "trace"), grid_hackr: other)
      log_in!

      post "/uplink/reads", params: {channel: "nope", last_read_message_id: first.id}
      expect(response).to have_http_status(:not_found)
      post "/uplink/reads", params: {channel: "secret", last_read_message_id: first.id}
      expect(response).to have_http_status(:forbidden)
      post "/uplink/reads", params: {channel: "ambient", last_read_message_id: elsewhere.id}
      expect(response).to have_http_status(:unprocessable_entity)
      post "/uplink/reads", params: {channel: "ambient", last_read_message_id: 0}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(UplinkChannelRead.count).to eq(0)
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
      expect(UplinkChannelRead.find_by!(grid_hackr: hackr, chat_channel: channel).last_read_message_id).to eq(ChatMessage.last.id) # your own packet is read
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

    it "toasts mentioned hackrs on their own stream with a link to the channel" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_call_original
      log_in!

      post "/uplink/packets", params: {channel_slug: "ambient", content: "yo @#{other.hackr_alias.upcase} look  at\nthis"},
        headers: turbo_stream_headers

      packet = ChatMessage.last
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        [other, :toasts], hash_including(target: "toast-region", partial: "shared/toast_mention", locals: {packet: packet})
      )
      expect(Turbo::StreamsChannel).not_to have_received(:broadcast_append_to).with([hackr, :toasts], anything)

      toast = ApplicationController.render(partial: "shared/toast_mention", locals: {packet: packet})
      expect(toast).to include('class="toast toast--mention"')
      expect(toast).to include('href="/uplink?channel=ambient"')
      expect(toast).to include('data-channel="ambient"')
      expect(toast).to include(%(data-packet-id="#{packet.id}"))
      expect(toast).to include("@MENTION")
      expect(toast).to include("#ambient")
      expect(toast).to include(%(<span class="toast-sender">@#{hackr.hackr_alias}</span>))
      expect(toast).to include("yo @#{other.hackr_alias.upcase} look at this") # squished excerpt
      expect(toast).to include('data-controller="toast"')
    end

    it "creates a reply to an active packet of the channel and renders the quote in the appended row" do
      parent = create(:chat_message, chat_channel: channel, grid_hackr: other, content: "original")
      log_in!

      expect {
        post "/uplink/packets", params: {channel_slug: "ambient", content: "my reply", reply_to_id: parent.id},
          headers: turbo_stream_headers
      }.to change(ChatMessage, :count).by(1)

      expect(response).to have_http_status(:ok)
      reply = ChatMessage.last
      expect(reply.reply_to).to eq(parent)
      expect(response.body).to include('action="append" target="uplink-log"')
      expect(response.body).to include(%(data-reply-to="#{parent.id}"))
      expect(response.body).to include(%(<span class="packet-reply-author packet-reply-author--operative">@#{other.hackr_alias}</span>))
      expect(response.body).to include('<span class="packet-reply-excerpt">original</span>')
      expect(response.body).to include("my reply")
    end

    it "refuses a reply to a dropped, foreign-channel or unknown packet with a form error and keeps nothing" do
      dropped = create(:chat_message, :dropped, chat_channel: channel, grid_hackr: other)
      elsewhere = create(:chat_message, chat_channel: create(:chat_channel, slug: "trace"), grid_hackr: other)
      log_in!

      [dropped.id, elsewhere.id, 0, "abc", 10**9].each do |target|
        expect {
          post "/uplink/packets", params: {channel_slug: "ambient", content: "orphan", reply_to_id: target},
            headers: turbo_stream_headers
        }.not_to change(ChatMessage, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('action="replace" target="uplink-form-error"')
        expect(response.body).to include(Uplink::PacketsController::REPLY_TARGET_GONE)
      end

      # A blank reply_to_id is a plain packet (the hidden field submits empty).
      post "/uplink/packets", params: {channel_slug: "ambient", content: "plain", reply_to_id: ""},
        headers: turbo_stream_headers
      expect(response).to have_http_status(:ok)
      expect(ChatMessage.last.reply_to).to be_nil
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

  describe "channel pins (GET /uplink/pins, POST /uplink/packets/:id/pin | unpin)" do
    let!(:packet) { create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Pin candidate") }

    def frame_headers
      {"Turbo-Frame" => "uplink-pins"}
    end

    def panel_body
      response.body[/<turbo-frame id="uplink-pins">.*<\/turbo-frame>/m]
    end

    it "renders the header's [◆] with the count of pinned active packets, the marker + PIN badge on those rows, and the hidden ◆ control (pin or unpin) on every active row" do
      pinned = create(:chat_message, :pinned, chat_channel: channel, grid_hackr: other, content: "Pinned signal")
      create(:chat_message, :pinned, :dropped, chat_channel: channel, grid_hackr: other, content: "Pinned then dropped")
      log_in!

      get "/uplink"

      body = response.body
      expect(body).to include(%(class="uplink-chanhead-button uplink-chanhead-pins" title="Pinned packets"))
      expect(body).to include(%(data-action="click->popover#open" data-popover-url-param="/uplink/pins?channel=ambient"))
      expect(body).to match(%r{data-popover-frame-param="uplink-pins" data-popover-align-param="end">\[◆\]<span class="uplink-chanhead-label"> PINNED</span>\s+<span id="uplink-pins-count" class="uplink-chanhead-count" data-count="1">1</span>\s*</button>})
      pins_frame = body[/<turbo-frame [^>]*id="uplink-pins"[^>]*>/] # turbo_frame_tag puts the id last
      expect(pins_frame).to include('target="_top"', "hidden", 'class="uplink-pins-frame"', 'data-popover-target="frame"')
      expect(body).to match(/id="chat_message_#{pinned.id}"\s+class="packet packet--pinned"/)
      expect(body).to include('<span class="packet-badge packet-badge--pinned" title="Pinned">PIN</span>')
      expect(body.scan("packet-badge--pinned").size).to eq(1) # the plain packet has none (the dropped one is not in the log)
      expect(body).not_to match(/id="chat_message_#{packet.id}"\s+class="packet packet--pinned"/)
      # The hover control: pin on the plain row, unpin on the pinned one; hidden until the packet controller reveals it for operators.
      pin_form = body[%r{<form[^>]*action="/uplink/packets/#{packet.id}/pin"[^>]*>.*?</form>}m]
      expect(pin_form).to include('hidden="hidden"', 'data-packet-target="pinControl"', 'class="uplink-inline-form uplink-pin-form"', 'method="post"')
      expect(pin_form).to include('<button class="packet-action-button packet-pin-button" title="Pin packet" type="submit">◆</button>')
      unpin_form = body[%r{<form[^>]*action="/uplink/packets/#{pinned.id}/unpin"[^>]*>.*?</form>}m]
      expect(unpin_form).to include('hidden="hidden"', 'data-packet-target="pinControl"')
      expect(unpin_form).to include('<button class="packet-action-button packet-pin-button packet-pin-button--on" title="Unpin packet" type="submit">◆</button>')
    end

    it "omits the header button and count on an unviewable channel" do
      live = create(:chat_channel, :livestream_only, slug: "live", name: "#live")
      create(:chat_message, :pinned, chat_channel: live, grid_hackr: other, content: "Offline pin")
      log_in!

      get "/uplink", params: {channel: "live"}

      expect(response.body).to include("#live is only available during livestreams.")
      expect(response.body).not_to include("uplink-chanhead-pins")
      expect(response.body).not_to include("uplink-pins-count")
    end

    describe "GET /uplink/pins" do
      it "requires login, and outside a frame goes to the channel" do
        get "/uplink/pins", params: {channel: "ambient"}, headers: frame_headers
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/grid/login")

        log_in!
        get "/uplink/pins", params: {channel: "ambient"}
        expect(response).to redirect_to("/uplink?channel=ambient")
      end

      it "lists the channel's pinned active packets newest pin first — sender, age, excerpt, jump — and no UNPIN for an operative" do
        first = create(:chat_message, :pinned, chat_channel: channel, grid_hackr: other, pinned_at: 2.hours.ago, created_at: 3.hours.ago,
          content: "First pin, a fairly long announcement that keeps going on and on. " * 4)
        second = create(:chat_message, :pinned, chat_channel: channel, grid_hackr: operator, content: "Second pin", pinned_at: 1.hour.ago, created_at: 2.days.ago)
        create(:chat_message, :pinned, :dropped, chat_channel: channel, grid_hackr: other, content: "Dropped pin")
        create(:chat_message, :pinned, chat_channel: create(:chat_channel, slug: "trace"), grid_hackr: other, content: "Other channel pin")
        bridged = create(:chat_message, :pinned, chat_channel: channel, grid_hackr: other, content: "[Twitch] viewer_42: hello from twitch",
          source: "TTV", pinned_at: 30.minutes.ago, created_at: 50.minutes.ago)
        create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Never pinned")
        log_in!(hackr)

        get "/uplink/pins", params: {channel: "ambient"}, headers: frame_headers

        expect(response).to have_http_status(:ok)
        panel = panel_body
        expect(panel).to include('class="uplink-pins" role="dialog" tabindex="-1"')
        expect(panel).to include('aria-label="Pinned packets in #ambient"')
        expect(panel).to include('<span class="uplink-pins-kicker">PINNED</span>')
        expect(panel).to include('<span class="uplink-pins-channel">#ambient</span>')
        expect(panel).to include('data-action="click->popover#dismiss"')
        expect(panel).to include('<div id="uplink-pins-list" class="uplink-pins-body">')
        expect(panel).to include('<p class="uplink-pins-count">3 / 50</p>')
        expect(panel.scan(/id="uplink-pin-(\d+)"/).flatten.map(&:to_i)).to eq([bridged.id, second.id, first.id])
        expect(panel).to include(%(<button type="button" class="uplink-pin-jump" title="Jump to packet"\n    data-action="click->popover#jump" data-popover-id-param="#{first.id}">))
        expect(panel).to include(%(<span class="uplink-pin-sender uplink-pin-sender--operative">@#{other.hackr_alias}</span>))
        expect(panel).to include(%(<span class="uplink-pin-sender uplink-pin-sender--operator">@#{operator.hackr_alias}</span>))
        expect(panel).to include('<span class="uplink-pin-sender uplink-pin-sender--bridged">TTV viewer_42</span>')
        expect(panel).to include('<span class="uplink-pin-excerpt">hello from twitch</span>')
        expect(panel).to include('<span class="uplink-pin-age">3H</span>')
        expect(panel).to include('<span class="uplink-pin-age">2D</span>')
        expect(panel).to include('<span class="uplink-pin-age">50M</span>')
        expect(panel).to match(/<span class="uplink-pin-excerpt">First pin, a fairly long announcement.{80,140}\.\.\.<\/span>/) # 160-char excerpt
        expect(panel).not_to include("Dropped pin")
        expect(panel).not_to include("Other channel pin")
        expect(panel).not_to include("Never pinned")
        expect(panel).not_to include("UNPIN") # operatives read, never curate
      end

      it "gives operators an UNPIN per row that asks the popover to stay and the reply to re-render the list" do
        pinned = create(:chat_message, :pinned, chat_channel: channel, grid_hackr: other, content: "Curated")
        log_in!(operator)

        get "/uplink/pins", params: {channel: "ambient"}, headers: frame_headers

        panel = panel_body
        expect(panel).to include(%(<form data-popover-stay="true" data-turbo-frame="_top" class="uplink-pin-unpin-form" method="post" action="/uplink/packets/#{pinned.id}/unpin?from=pins">))
        expect(panel).to include('<button class="uplink-pin-unpin" title="Unpin packet" type="submit">UNPIN</button>')
        expect(panel.scan(">UNPIN</button>").size).to eq(1)
      end

      it "renders the empty state (with the how-to for operators), refuses an off-limits channel inside the frame (403) and 404s an unknown one" do
        log_in!
        get "/uplink/pins", params: {channel: "ambient"}, headers: frame_headers
        expect(response).to have_http_status(:ok)
        expect(panel_body).to include('<p class="uplink-pins-note">No pinned packets.</p>')
        expect(panel_body).not_to include("uplink-pins-count")

        create(:chat_channel, :operator_only, slug: "ops", name: "#ops")
        get "/uplink/pins", params: {channel: "ops"}, headers: frame_headers
        expect(response).to have_http_status(:forbidden)
        expect(panel_body).to include('class="uplink-pins uplink-pins--empty"')
        expect(panel_body).to include("// NO CHANNEL //")
        expect(panel_body).to include("#ops is outside your clearance.")
        expect(panel_body).not_to include("uplink-pins-list")

        get "/uplink/pins", params: {channel: "nope"}, headers: frame_headers
        expect(response).to have_http_status(:not_found)
        expect(panel_body).to include("That channel is gone.")
      end

      it "tells operators how to pin when the channel has none" do
        log_in!(operator)

        get "/uplink/pins", params: {channel: "ambient"}, headers: frame_headers

        expect(panel_body).to include("No pinned packets. Hover a packet and hit ◆ to pin it.")
      end
    end

    describe "POST /uplink/packets/:id/pin" do
      it "lets an operator pin any active packet — their own too: the row re-renders pinned, the header count follows, the moderation log gets a row" do
        own = create(:chat_message, chat_channel: channel, grid_hackr: operator, content: "Operator's own")
        log_in!(operator)

        post "/uplink/packets/#{packet.id}/pin", headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(action="replace" target="chat_message_#{packet.id}"))
        expect(response.body).to match(/id="chat_message_#{packet.id}"\s+class="packet packet--pinned"/)
        expect(response.body).to include('title="Unpin packet"')
        expect(response.body).to include(%(action="replace" target="uplink-pins-count"))
        expect(response.body).to include('<span id="uplink-pins-count" class="uplink-chanhead-count" data-count="1">1</span>')
        expect(response.body).not_to include("uplink-pins-list") # the panel did not send this
        expect(packet.reload).to be_pinned
        expect(packet.pinned_by).to eq(operator)
        expect(ModerationLog.last).to have_attributes(action: "pin_packet", actor: operator, target: other, chat_message: packet)

        post "/uplink/packets/#{own.id}/pin", headers: turbo_stream_headers
        expect(response).to have_http_status(:ok)
        expect(own.reload).to be_pinned
        expect(response.body).to include('data-count="2"')
        expect(ModerationLog.count).to eq(2)
      end

      it "is a quiet success on a packet already pinned (a stale row): no second log row" do
        packet.pin!(operator)
        log_in!(operator)

        expect { post "/uplink/packets/#{packet.id}/pin", headers: turbo_stream_headers }.not_to change(ModerationLog, :count)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('data-count="1"')
      end

      it "refuses a dropped packet and a full channel with an error toast (422), and 404s an unknown packet" do
        log_in!(operator)
        packet.drop!
        post "/uplink/packets/#{packet.id}/pin", headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(%(action="append" target="toast-region"))
        expect(response.body).to include("toast--moderation-error")
        expect(response.body).to include("Cannot pin a dropped packet.")
        expect(packet.reload).not_to be_pinned

        stub_const("ChatMessage::PIN_CAP", 1)
        create(:chat_message, :pinned, chat_channel: channel, grid_hackr: other, content: "The one pin")
        fresh = create(:chat_message, chat_channel: channel, grid_hackr: other, content: "One too many")
        post "/uplink/packets/#{fresh.id}/pin", headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("#ambient already has 1 pinned packets.")
        expect(fresh.reload).not_to be_pinned
        expect(ModerationLog.count).to eq(0)

        post "/uplink/packets/0/pin", headers: turbo_stream_headers
        expect(response).to have_http_status(:not_found)
      end

      it "forbids operatives — the author included" do
        log_in!(other)

        post "/uplink/packets/#{packet.id}/pin", headers: turbo_stream_headers

        expect(response).to have_http_status(:forbidden)
        expect(packet.reload).not_to be_pinned
        expect(ModerationLog.count).to eq(0)
      end
    end

    describe "POST /uplink/packets/:id/unpin" do
      before { packet.pin!(operator) }

      it "lets an operator unpin: the row re-renders plain, the count follows, the log gets a row; from=pins re-renders the panel's list too" do
        log_in!(operator)

        post "/uplink/packets/#{packet.id}/unpin", headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(action="replace" target="chat_message_#{packet.id}"))
        expect(response.body).not_to include("packet--pinned")
        expect(response.body).to include('title="Pin packet"')
        expect(response.body).to include('data-count="0"')
        expect(response.body).not_to include("uplink-pins-list")
        expect(packet.reload).not_to be_pinned
        expect(packet.pinned_by).to be_nil
        expect(ModerationLog.last).to have_attributes(action: "unpin_packet", actor: operator, target: other, chat_message: packet)

        second = create(:chat_message, :pinned, chat_channel: channel, grid_hackr: other, content: "Still pinned")
        third = create(:chat_message, :pinned, chat_channel: channel, grid_hackr: other, content: "Leaving")
        post "/uplink/packets/#{third.id}/unpin", params: {from: "pins"}, headers: turbo_stream_headers
        expect(response.body).to include(%(action="replace" target="uplink-pins-list"))
        expect(response.body).to include('<p class="uplink-pins-count">1 / 50</p>')
        expect(response.body).to include(%(id="uplink-pin-#{second.id}"))
        expect(response.body).not_to include(%(id="uplink-pin-#{third.id}"))
        expect(response.body).to include(">UNPIN</button>")

        post "/uplink/packets/#{second.id}/unpin", params: {from: "pins"}, headers: turbo_stream_headers
        expect(response.body).to include("No pinned packets. Hover a packet and hit ◆ to pin it.")
      end

      it "is a quiet success on a packet that is not pinned" do
        packet.unpin!
        log_in!(operator)

        expect { post "/uplink/packets/#{packet.id}/unpin", headers: turbo_stream_headers }.not_to change(ModerationLog, :count)
        expect(response).to have_http_status(:ok)
      end

      it "forbids operatives" do
        log_in!(hackr)

        post "/uplink/packets/#{packet.id}/unpin", headers: turbo_stream_headers

        expect(response).to have_http_status(:forbidden)
        expect(packet.reload).to be_pinned
      end
    end
  end

  describe "reactions (GET | POST /uplink/packets/:id/reactions)" do
    let!(:packet) { create(:chat_message, chat_channel: channel, grid_hackr: other, content: "React to me") }
    let!(:wave) { create(:emote, slug: "wave") }

    def token(of)
      Uplink::Callsign.token(of.id)
    end

    def frame_headers
      {"Turbo-Frame" => "uplink-reactmenu"}
    end

    def menu_body
      response.body[/<turbo-frame id="uplink-reactmenu">.*<\/turbo-frame>/m]
    end

    # The chip row nests no div: the slice ends at its own close.
    def chips(id = packet.id)
      response.body[/<div id="reactions_chat_message_#{id}".*?<\/div>/m]
    end

    # The let! packet's own create broadcast rendered its chip row, which
    # loaded `reactions` (empty) on this very instance: read it fresh.
    def reactions
      packet.reload.reactions
    end

    it "renders the chip row under every packet (hidden while empty): one ':emote: N' toggle per emote in first-reaction order, reactors as callsign tokens, a token for an emote that is gone; plus the hover :) and the picker frame" do
      plain = create(:chat_message, chat_channel: channel, grid_hackr: other, content: "Nothing here")
      create(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "wave")
      create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "gone")
      create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "wave")
      log_in!

      get "/uplink"

      body = response.body
      row = chips
      expect(row).to start_with(%(<div id="reactions_chat_message_#{packet.id}" class="packet-reactions" data-controller="reactions">))
      expect(row).to include(%(<form class="packet-reaction-form" method="post" action="/uplink/packets/#{packet.id}/reactions?emote_slug=wave"><button class="packet-reaction" title=":wave: × 2" data-reactors="#{token(other)},#{token(hackr)}" data-emote="wave" type="submit">))
      expect(row).to include(%(<img src="#{wave.chat_url}" alt=":wave:" title=":wave:" class="emote" width="28" height="28" loading="eager"><span class="packet-reaction-count">2</span>))
      expect(row).to include(%(action="/uplink/packets/#{packet.id}/reactions?emote_slug=gone"><button class="packet-reaction" title=":gone: × 1" data-reactors="#{token(hackr)}" data-emote="gone" type="submit">))
      expect(row).to include('<span class="packet-reaction-token">:gone:</span><span class="packet-reaction-count">1</span>')
      expect(row.index("emote_slug=wave")).to be < row.index("emote_slug=gone")
      expect(row).not_to include(hackr.hackr_alias, other.hackr_alias) # reactors are tokens, never aliases
      expect(chips(plain.id)).to match(%r{<div id="reactions_chat_message_#{plain.id}" class="packet-reactions" data-controller="reactions" hidden>\s*</div>})
      expect(body).to match(%r{<button type="button" class="packet-action-button packet-react-button" title="React to packet"\s+data-action="click->popover#open" data-popover-url-param="/uplink/packets/#{packet.id}/reactions"\s+data-popover-frame-param="uplink-reactmenu">:\)</button>})
      frame = body[/<turbo-frame [^>]*id="uplink-reactmenu"[^>]*>/] # turbo_frame_tag puts the id last
      expect(frame).to include('target="_top"', 'hidden="hidden"', 'class="uplink-reactmenu-frame"', 'data-popover-target="frame"')
      expect(body).to include(%(<meta name="uplink-callsign" content="#{token(hackr)}">))
    end

    it "hides the chips while the packet is dropped (the reactions wait) and shows them again on restore" do
      create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "wave")
      log_in!(operator)

      post "/uplink/packets/#{packet.id}/drop", headers: turbo_stream_headers
      expect(chips).to match(%r{<div id="reactions_chat_message_#{packet.id}" class="packet-reactions" data-controller="reactions" hidden>\s*</div>})
      expect(reactions.count).to eq(1)

      post "/uplink/packets/#{packet.id}/restore", headers: turbo_stream_headers
      expect(chips).to include(%(title=":wave: × 1" data-reactors="#{token(hackr)}"))
    end

    describe "GET /uplink/packets/:id/reactions" do
      it "requires login, and outside a frame goes to the channel" do
        get "/uplink/packets/#{packet.id}/reactions", headers: frame_headers
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/grid/login")

        log_in!
        get "/uplink/packets/#{packet.id}/reactions"
        expect(response).to redirect_to("/uplink?channel=ambient")
      end

      it "lists every chat-ready emote as a pick in slug order, the viewer's own reactions marked, disabled emotes left out" do
        create(:emote, slug: "gg")
        create(:emote, :disabled, slug: "off")
        create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "gg")
        create(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "wave")
        log_in!

        get "/uplink/packets/#{packet.id}/reactions", headers: frame_headers

        expect(response).to have_http_status(:ok)
        menu = menu_body
        expect(menu).to include('class="uplink-reactmenu" role="dialog" tabindex="-1"')
        expect(menu).to include(%(aria-label="React to @#{other.hackr_alias}"))
        expect(menu).to include('<span class="uplink-reactmenu-kicker">REACT</span>')
        expect(menu).to include(%(<span class="uplink-reactmenu-target uplink-reactmenu-target--operative">@#{other.hackr_alias}</span>))
        expect(menu).to include('data-action="click->popover#dismiss">[x]</button>')
        expect(menu).to include(%(<form class="uplink-reactmenu-form" data-turbo-frame="_top" action="/uplink/packets/#{packet.id}/reactions" accept-charset="UTF-8" method="post">))
        expect(menu).to match(%r{<button type="submit" name="emote_slug" value="gg" title=":gg:"\s+class="uplink-reactmenu-emote uplink-reactmenu-emote--on"\s+aria-pressed="true"><img [^>]*alt=":gg:"[^>]*></button>})
        expect(menu).to match(%r{<button type="submit" name="emote_slug" value="wave" title=":wave:"\s+class="uplink-reactmenu-emote"\s+aria-pressed="false"><img [^>]*alt=":wave:"})
        expect(menu).not_to include('value="off"')
        expect(menu.index('value="gg"')).to be < menu.index('value="wave"')
      end

      it "renders the empty states in the frame at the real status: no emotes, a gone or dropped packet, an off-limits channel" do
        log_in!
        Emote.destroy_all
        get "/uplink/packets/#{packet.id}/reactions", headers: frame_headers
        expect(response).to have_http_status(:ok)
        expect(menu_body).to include('<p class="uplink-reactmenu-note">No emotes on the node yet.</p>')
        expect(menu_body).not_to include("uplink-reactmenu-form")

        packet.drop!
        get "/uplink/packets/#{packet.id}/reactions", headers: frame_headers
        expect(response).to have_http_status(:not_found)
        expect(menu_body).to include('class="uplink-reactmenu uplink-reactmenu--empty"', "// NO PACKET //", '<p class="uplink-reactmenu-note">That packet is gone.</p>')
        expect(menu_body).not_to include("uplink-reactmenu-form")

        get "/uplink/packets/0/reactions", headers: frame_headers
        expect(response).to have_http_status(:not_found)
        expect(menu_body).to include("That packet is gone.")

        live = create(:chat_channel, :livestream_only, slug: "live", name: "#live")
        offline = create(:chat_message, chat_channel: live, grid_hackr: other, content: "Offline")
        get "/uplink/packets/#{offline.id}/reactions", headers: frame_headers
        expect(response).to have_http_status(:forbidden)
        expect(menu_body).to include("// NO PACKET //", "#live is outside your clearance.")
      end
    end

    describe "POST /uplink/packets/:id/reactions" do
      it "requires login" do
        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/grid/login")
        expect(reactions).to be_empty
      end

      it "toggles the viewer's reaction: on (the chip row replaces, their token on the chip), off on a second post, stacking on another viewer's emote in first-reaction order" do
        create(:emote, slug: "gg")
        create(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "gg")
        log_in!

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(<turbo-stream action="replace" target="reactions_chat_message_#{packet.id}">))
        expect(response.body).not_to include("toast-region")
        row = chips
        expect(row).to include(%(title=":gg: × 1" data-reactors="#{token(other)}" data-emote="gg"))
        expect(row).to include(%(title=":wave: × 1" data-reactors="#{token(hackr)}" data-emote="wave"))
        expect(row.index('data-emote="gg"')).to be < row.index('data-emote="wave"')
        expect(reactions.pluck(:grid_hackr_id, :emote_slug)).to eq([[other.id, "gg"], [hackr.id, "wave"]])

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "gg"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:ok)
        expect(chips).to include(%(title=":gg: × 2" data-reactors="#{token(other)},#{token(hackr)}" data-emote="gg"))

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:ok)
        expect(chips).not_to include('data-emote="wave"')
        expect(chips).to include('title=":gg: × 2"')
        expect(reactions.pluck(:grid_hackr_id, :emote_slug)).to eq([[other.id, "gg"], [hackr.id, "gg"]])

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "gg"}, headers: turbo_stream_headers
        expect(chips).to include(%(title=":gg: × 1" data-reactors="#{token(other)}"))

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "wave"} # plain HTML: back to the channel
        expect(response).to redirect_to("/uplink?channel=ambient")
        expect(reactions.where(grid_hackr: hackr).pluck(:emote_slug)).to eq(["wave"])
      end

      it "removes a reaction whose emote is no longer chat-ready, but never adds one: an error toast at 422" do
        create(:emote, :disabled, slug: "off")
        create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "off")
        log_in!

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "off"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:ok)
        expect(reactions).to be_empty

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "off"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('<turbo-stream action="append" target="toast-region">', "toast--moderation-error")
        expect(response.body).to include('<div class="toast-kicker toast-kicker--moderation">REACTIONS</div>', "Unknown emote.")
        expect(reactions).to be_empty

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "nope"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_entity)
        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: ""}, headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(reactions).to be_empty
      end

      it "caps a packet at REACTION_CAP distinct emotes: joining an existing chip still works, a new emote does not" do
        stub_const("ChatMessage::REACTION_CAP", 1)
        create(:emote, slug: "gg")
        create(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "gg")
        log_in!

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("This packet already has 1 reaction.")
        expect(reactions.count).to eq(1)

        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "gg"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:ok)
        expect(chips).to include('title=":gg: × 2"')
      end

      it "refuses a dropped packet, a squelched or blacked-out viewer and an off-limits channel at the real status; 404 for a gone packet" do
        log_in!
        packet.drop!
        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Cannot react to a dropped packet.")
        packet.restore!

        UserPunishment.squelch!(hackr, issued_by: operator, duration_minutes: 10)
        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("You have been squelched. Please wait for your squelch to expire.")

        UserPunishment.blackout!(hackr, issued_by: operator)
        post "/uplink/packets/#{packet.id}/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("You have been blackedout from Uplink.")
        expect(reactions).to be_empty

        log_in!(other)
        live = create(:chat_channel, :livestream_only, slug: "live", name: "#live")
        offline = create(:chat_message, chat_channel: live, grid_hackr: other, content: "Offline")
        post "/uplink/packets/#{offline.id}/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include("#live is outside your clearance.")

        post "/uplink/packets/0/reactions", params: {emote_slug: "wave"}, headers: turbo_stream_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
