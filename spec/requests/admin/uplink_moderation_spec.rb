require "rails_helper"

# /root/uplink's moderation screens as consoles (console-ui-for-all-admin
# Phase 2, 2026-10-31): the uplink screen's IN FORCE / RECENT PACKETS /
# RECENT ACTIVITY ledgers, the packets ledger + its filter, the
# punishments screen (ISSUE without a script — [BLACKOUT] is a
# formaction), the moderation log + its filter. Channels:
# uplink_channels_spec.rb.
RSpec.describe "Admin uplink moderation", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:target) { create(:grid_hackr, hackr_alias: "ghostline", password: "hackthegrid") }
  let!(:channel) { create(:chat_channel, slug: "ambient", name: "#ambient", category: "COMMS") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(target)

    %w[/root/uplink /root/uplink/packets /root/uplink/punishments /root/uplink/moderation_log].each do |path|
      get path
      expect(response).not_to have_http_status(:ok), path
    end
  end

  it "draws the punishments in force, the recent packets and the recent activity on the uplink screen" do
    create(:user_punishment, :blackout, grid_hackr: target, issued_by: admin, reason: "flooding #ambient")
    create(:chat_message, chat_channel: channel, grid_hackr: target, content: "hello from the stack")
    create(:moderation_log, actor: admin, target: target, action: "blackout", reason: "flooding #ambient")
    log_in!(admin)

    get "/root/uplink"

    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("// IN FORCE · 1 PUNISHMENT //", "@ghostline", "flooding #ambient", "BLACKOUT", "PERMANENT", "[LIFT]")
    expect(body).to include("// RECENT PACKETS //", "hello from the stack", "// RECENT ACTIVITY //", "@#{admin.hackr_alias}")
    expect(body).to include("[PACKETS]", "[PUNISH]", "[MODLOG]", "[WIRE]").and include("a channel number")
    expect(body).not_to include("[UPLINK]")
  end

  it "shortens a long packet on the uplink screen and shows it whole on the packets ledger" do
    long = "x" * 140
    create(:chat_message, chat_channel: channel, grid_hackr: target, content: long)
    log_in!(admin)

    get "/root/uplink"
    expect(response.body).to include("#{"x" * 97}...")
    expect(response.body).not_to include(long)

    get "/root/uplink/packets"
    expect(response.body).to include(long)
  end

  describe "packets" do
    it "lists packets with drop / restore / delete and filters by channel, status, hackr and content" do
      live = create(:chat_message, chat_channel: channel, grid_hackr: target, content: "hello from the stack")
      dropped = create(:chat_message, :dropped, chat_channel: channel, grid_hackr: target, content: "spam spam spam")
      other = create(:chat_channel, slug: "ops", name: "#ops", category: "COMMS")
      create(:chat_message, chat_channel: other, content: "ops chatter")
      log_in!(admin)

      get "/root/uplink/packets"

      body = response.body
      expect(body).to be_console_clean
      expect(body).to include("PACKETS", "3 packets", "1 dropped", "// FILTER //", "// PACKETS //", "hello from the stack", "[DROPPED]", "ops chatter")
      expect(body).to include(%(action="/root/uplink/packets/#{live.id}/drop"), %(action="/root/uplink/packets/#{dropped.id}/restore"), %(action="/root/uplink/packets/#{live.id}"))
      expect(body).to include('<select name="channel" id="channel" class="rc-select">', '<option value="ambient">#ambient</option>', 'name="username"', 'name="search"')

      get "/root/uplink/packets", params: {channel: "ambient", status: "active", username: "ghostline"}
      body = response.body
      expect(body).to include("hello from the stack", "1 packet", "filtered", '<option selected="selected" value="ambient">#ambient</option>')
      expect(body).not_to include("ops chatter")
      expect(body).not_to include(%(action="/root/uplink/packets/#{dropped.id}/restore"))
      expect(body).to include('href="/root/uplink/packets?channel=ambient&amp;status=dropped&amp;username=ghostline"')

      # An unknown status filters nothing, so it reads unfiltered with ALL lit and is not carried forward.
      get "/root/uplink/packets", params: {status: "bogus"}
      body = response.body
      expect(body).to include("3 packets", %(class="rc-btn rc-btn--on" aria-current="page" href="/root/uplink/packets">ALL</a>))
      expect(body).not_to include("filtered", 'name="status"')
    end

    it "drops a packet and logs it" do
      packet = create(:chat_message, chat_channel: channel, grid_hackr: target)
      log_in!(admin)

      post "/root/uplink/packets/#{packet.id}/drop"
      follow_redirect!

      expect(response.body).to include("[OK]", "Packet by @ghostline dropped.")
      expect(ModerationLog.last).to have_attributes(action: "drop_packet", actor_id: admin.id)
    end
  end

  describe "punishments" do
    it "issues from a scriptless form — [SQUELCH] on the form's action, [BLACKOUT] as its formaction — and filters by status and type" do
      create(:user_punishment, :squelch, :expired, grid_hackr: target, issued_by: admin, reason: "old news")
      log_in!(admin)

      get "/root/uplink/punishments"

      body = response.body
      expect(body).to be_console_clean
      expect(body).not_to include("/api/grid/current_hackr", "punishment-type")
      expect(body).to include('id="punishment-form"', 'action="/root/uplink/users/0/squelch"', 'formaction="/root/uplink/users/0/blackout"')
      expect(body).to include('data-confirm="Squelch this hackr?', 'data-confirm="Black out this hackr?')
      expect(body).to include('name="username"', 'name="duration_minutes"', 'name="reason"', "[SQUELCH]", "[BLACKOUT]")
      expect(body).to include("1 punishment", "0 in force", "old news", "EXPIRED")
      expect(body).to include('href="/root/uplink/punishments?status=active"', 'href="/root/uplink/punishments?type=blackout"')

      get "/root/uplink/punishments", params: {status: "active", type: "squelch"}
      expect(response.body).to include("NO PUNISHMENTS FOUND", 'href="/root/uplink/punishments?status=active&amp;type=blackout"')

      # Unknown values light ALL and are not carried into the other row's links.
      get "/root/uplink/punishments", params: {status: "bogus", type: "bogus"}
      expect(response.body).to include("old news", 'href="/root/uplink/punishments?status=active"', 'href="/root/uplink/punishments?type=blackout"')
      expect(response.body).not_to include("bogus")
    end

    it "squelches by alias for a while, blacks out for good, and lifts" do
      log_in!(admin)

      post "/root/uplink/users/0/squelch", params: {username: "@ghostline", duration_minutes: "30", reason: "cool off"}
      follow_redirect!
      expect(response.body).to include("[OK]", "ghostline has been squelched for 30 minutes.")

      post "/root/uplink/users/0/blackout", params: {username: "ghostline", duration_minutes: "", reason: ""}
      expect(UserPunishment.blackedout?(target)).to be(true)

      get "/root/uplink/punishments"
      expect(response.body).to include("SQUELCH", "BLACKOUT", "cool off", "no reason given", "2 in force")

      blackout = UserPunishment.blackouts.last
      delete "/root/uplink/punishments/#{blackout.id}"
      follow_redirect!
      expect(response.body).to include("[OK]", "Punishment lifted for @ghostline.")
    end

    it "says which alias it could not find" do
      log_in!(admin)

      post "/root/uplink/users/0/squelch", params: {username: "nobody"}
      follow_redirect!

      expect(response.body).to include("[ERR]", "User &#39;nobody&#39; not found.")
    end
  end

  it "shows a log entry's reason in full" do
    reason = "repeated flooding of #ambient after two warnings, then evading the squelch with a second account — permanent"
    create(:moderation_log, actor: admin, target: target, action: "blackout", reason: reason)
    log_in!(admin)

    get "/root/uplink/moderation_log"

    expect(reason.length).to be > 100
    expect(response.body).to include(%("#{ERB::Util.html_escape(reason)}"))
  end

  it "lists the moderation log and filters by action, actor and target" do
    create(:moderation_log, actor: admin, target: target, action: "squelch", duration_minutes: 30, reason: "cool off")
    create(:moderation_log, actor: admin, target: target, action: "drop_packet", reason: nil)
    log_in!(admin)

    get "/root/uplink/moderation_log"

    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("MODERATION LOG", "2 entries", "// LOG //", "SQUELCH", "DROP PACKET", "30 min", "cool off", "@ghostline")
    expect(body).to include('<option value="drop_packet">DROP PACKET</option>', 'name="actor"', 'name="target"')

    get "/root/uplink/moderation_log", params: {action_type: "squelch", target: "ghostline"}
    body = response.body
    expect(body).to include("1 entry", "filtered", "cool off")
    expect(body).not_to include("DROP PACKET</span>")
  end
end
