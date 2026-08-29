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

    it "renders the panel with recent packets, form, and stream subscription" do
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

    it "switches channels via ?channel= and marks the active tab" do
      trace = create(:chat_channel, slug: "trace", name: "#trace")
      create(:chat_message, chat_channel: trace, grid_hackr: other, content: "Trace-only packet")
      log_in!

      get "/uplink", params: {channel: "trace"}

      expect(response.body).to include('data-uplink-channel-value="trace"')
      expect(response.body).to include("Trace-only packet")
      expect(response.body).to include("channel-tab channel-tab--active")
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
