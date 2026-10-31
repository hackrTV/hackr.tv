require "rails_helper"

# The admin layout's chrome — the /root nav bar and the RED FLAGS strip
# (admin/shared/_nav, _data_audit_banner, admin_chrome.css,
# Admin::NavHelper; 2026-10-30).
RSpec.describe "Admin chrome", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "renders the nav as one classed sticky bar with the brand, the alias and every section" do
    log_in!(admin)

    get "/root"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('<header class="admin-chrome" data-controller="site-header">')
    expect(body).to include('<nav class="admin-nav" aria-label="Admin">')
    expect(body).to include('class="admin-nav-brand" href="/root"')
    expect(body).to include("@<span class=\"purple-168-text\">#{admin.hackr_alias}</span>")
    expect(body).to match(%r{<link rel="stylesheet" href="/assets/admin_chrome-\h+\.css"})
    expect(body).not_to include("<style>") # the nav's rules moved into admin_chrome.css
    %w[Dashboard Music Logs Codex Handbook Streams PulseWire Emotes Uplink Grid Hackrs Meta].each do |section|
      expect(body).to include(">#{section}<"), "expected the #{section} item"
    end
    expect(body).to include('href="/">[&lt;] EXIT</a>') # console tag, not a fallback ← glyph
    expect(body[%r{<nav class="admin-nav".*?</nav>}m]).not_to match(/[←→▾⚑]/)
    expect(body.scan('class="admin-nav-dropdown-menu"').size).to eq(4)
  end

  it "lights the dashboard item on /root and nothing else" do
    log_in!(admin)

    get "/root"

    body = response.body
    expect(body).to match(%r{<li class="is-active">\s*<a class="cyan-168-text is-active" aria-current="page" href="/root">Dashboard</a>\s*</li>})
    expect(body.scan(/<li class="[^"]*\bis-active\b/).size).to eq(1)
    expect(body.scan('aria-current="page"').size).to eq(1)
  end

  it "lights the section and the entry inside its menu" do
    create(:artist, :xeraen)
    log_in!(admin)

    get "/root/artists"

    body = response.body
    expect(body).to include('<li class="admin-nav-dropdown is-active">')
    expect(body).to match(%r{<li class="admin-nav-dropdown is-active">\s*<span class="admin-nav-dropdown-trigger cyan-168-text">Music</span>})
    expect(body).to include('<a class="cyan-168-text is-active" aria-current="page" href="/root/artists">Artists</a>')
    expect(body).to include('<a class="cyan-168-text" href="/root/releases">Releases</a>')
    expect(body.scan(/<li class="[^"]*\bis-active\b/).size).to eq(1)
  end

  it "lights Hackrs, not Grid, on the hackr records" do
    log_in!(admin)

    get "/root/grid_hackrs"

    body = response.body
    expect(body).to match(%r{<li class="is-active">\s*<a [^>]*class="(green|yellow)-168-text is-active" aria-current="page" href="/root/grid_hackrs">Hackrs</a>})
    expect(body).not_to match(%r{<li class="admin-nav-dropdown is-active">\s*<span class="admin-nav-dropdown-trigger green-168-text">Grid</span>})
  end

  it "shows the RED FLAGS strip only while flags are open" do
    log_in!(admin)
    allow(DataAudit::FlagCache).to receive(:open_count).and_return(0)

    get "/root"
    expect(response.body).not_to include("admin-banner--flags")

    allow(DataAudit::FlagCache).to receive(:open_count).and_return(3)

    get "/root"
    body = response.body
    expect(body).to include('<div class="admin-banner admin-banner--flags" role="status">')
    expect(body).to include("[!] RED FLAGS: 3 open")
    expect(body).to include('href="/root/data_audit_flags">[&gt;] VIEW ALL</a>')
    expect(body).not_to include("⚑")
    expect(body.index("admin-nav")).to be < body.index("admin-banner--flags")
    expect(body.index("admin-banner--flags")).to be < body.index('class="console console--root"')
  end
end
