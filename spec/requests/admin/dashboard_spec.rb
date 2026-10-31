require "rails_helper"

# /root — the admin dashboard as a console screen (admin/dashboard/index,
# Admin::ConsoleHelper::ROOT_SECTIONS, admin/console/* partials;
# console-ui-for-all-admin Phase 0, 2026-10-30).
RSpec.describe "Admin dashboard", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  # .env sets ADMIN_DEV_TOOLS=true for local work; the gate is off here
  # unless an example turns it on.
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return(nil)
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root"

    expect(response).not_to have_http_status(:ok)
  end

  it "renders the root console: the bar, the SYSTEM tiles, every section's destination rows, the recent ledgers and the prompt" do
    xeraen = create(:artist, :xeraen)
    release = create(:release, artist: xeraen, name: "OMNIWAVE GENESIS")
    track = create(:track, artist: xeraen, release: release, title: "Signal Decay", featured: true)
    create(:hackr_log, :published, title: "Uplink Restored", grid_hackr: admin)
    create(:hackr_log, title: "Draft Transmission", grid_hackr: admin)
    online = create(:grid_hackr, :online, hackr_alias: "ghostline")
    log_in!(admin)

    get "/root"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include('<h1 class="console-bar-title">ROOT</h1>')
    expect(body).to include("ADMIN · /root · @#{admin.hackr_alias}")
    expect(body).to include('data-command="site" href="/">[&gt;] SITE</a>')
    expect(body).to include("// SYSTEM //")
    expect(body).to include('<span class="rc-stat-key">ONLINE</span><span class="rc-stat-val rc-on">1</span>')
    expect(body).to include('<span class="rc-stat-key">ARTISTS</span><span class="rc-stat-val">1</span>')
    expect(body).to include('<span class="rc-stat-key">TRACKS</span><span class="rc-stat-val">1</span>')
    expect(body).to include('<span class="rc-stat-key">LOGS</span><span class="rc-stat-val">2</span>')
    expect(body).to include('<span class="rc-stat-key">MAIL TOTAL</span><span class="rc-stat-val">0</span>')
    %w[MUSIC CONTENT STREAMS MODERATION WORLD SYSTEMS HACKRS META].each do |section|
      expect(body).to include("// #{section} //"), "expected the #{section} rule"
    end
    expect(body).to include('<span class="console-tag">[ARTISTS]</span>')
    expect(body).to include('<a class="console-link" data-command="artists" href="/root/artists">Artists</a>')
    expect(body).to include('data-command="errors" href="/root/error_groups"')
    expect(body).to include('data-command="map" href="/root/grid_map_editor/region/')
    expect(body.scan("[RADIO]").size).to eq(1) # music and streams both list it; the first row keeps it
    expect(body).not_to include("[SANDBOX]") # dev tools off
    expect(body).not_to include("DEV TOOLS ON")
    expect(body).to include("// RECENT TRACKS //")
    expect(body).to include(%(data-command="01" href="/root/tracks/#{track.slug}/edit">Signal Decay</a>))
    expect(body).to include("XERAEN · OMNIWAVE GENESIS")
    expect(body).to include('<span class="rc-cell rc-star">★ FEATURED</span>')
    expect(body).to include("// RECENT LOGS //")
    expect(body).to include("Uplink Restored")
    expect(body).to include('<span class="rc-cell rc-on">PUBLISHED</span>')
    expect(body).to include('<span class="rc-cell rc-off">DRAFT</span>')
    expect(body).to include("// ONLINE HACKRS //")
    expect(body).to include(%(data-command="04" href="/root/grid_hackrs/#{online.id}">ghostline</a>))
    expect(body).to include(ERB::Util.html_escape(online.current_room.name))
    expect(body).to include('<span class="rc-cell rc-on">ONLINE</span>')
    expect(body).to include("[INSPECT]")
    expect(body).to include("// END OF LINE //")
    expect(body).to include("type a tag ")
    expect(body).to include("(01–04)")
  end

  it "reads the empty ledgers" do
    log_in!(admin)

    get "/root"

    body = response.body
    expect(body).to include('<span class="rc-stat-key">ONLINE</span><span class="rc-stat-val rc-off">0</span>')
    expect(body).to include("NO TRACKS ON RECORD")
    expect(body).to include("NO LOGS ON RECORD")
    expect(body).to include("NO HACKRS ON THE GRID")
    expect(body).not_to include("or a number")
  end

  it "badges DEV TOOLS and lists the dev-tool screens while the gate is on" do
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return("true")
    log_in!(admin)

    get "/root"

    body = response.body
    expect(body).to include('<span class="console-bar-badge rc-badge--warn">DEV TOOLS ON</span>')
    expect(body).to include('data-command="sandbox" href="/root/grid_breach_sandbox/new"')
    expect(body).to include('data-command="npc" href="/root/grid_npc_dialogue_tester/new"')
    expect(body).to include('data-command="pac" href="/root/grid_pac_escape_tester/new"')
  end

  it "replies [ERR] under the bar when a gated screen bounces here" do
    log_in!(admin)

    get "/root/grid_breach_sandbox/new"

    expect(response).to redirect_to("/root")
    follow_redirect!
    expect(response.body).to include('<span class="console-tag">[ERR]</span><span>DEV TOOLS DISABLED. Set ADMIN_DEV_TOOLS=true to enable.</span>')
  end
end
