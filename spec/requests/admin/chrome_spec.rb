require "rails_helper"

# The admin layout's chrome — the /root nav bar and the RED FLAGS strip
# (admin/shared/_nav, _data_audit_banner, admin_chrome.css; 2026-10-30).
RSpec.describe "Admin chrome", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "renders the nav as one classed bar with the brand, the alias and every section" do
    log_in!(admin)

    get "/root"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('<header class="admin-chrome">')
    expect(body).to include('<nav class="admin-nav" aria-label="Admin">')
    expect(body).to include('class="admin-nav-brand" href="/root"')
    expect(body).to include("@<span class=\"purple-168-text\">#{admin.hackr_alias}</span>")
    expect(body).to match(%r{<link rel="stylesheet" href="/assets/admin_chrome-\h+\.css"})
    expect(body).not_to include("<style>") # the nav's rules moved into admin_chrome.css
    %w[Dashboard Music Logs Codex Handbook Streams PulseWire Emotes Uplink Grid Hackrs Meta].each do |section|
      expect(body).to include(">#{section}<"), "expected the #{section} item"
    end
    expect(body).to include('href="/">← Exit</a>')
    expect(body.scan('class="admin-nav-dropdown-menu"').size).to eq(4)
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
    expect(body).to include("⚑ RED FLAGS: 3 open")
    expect(body).to include('href="/root/data_audit_flags">View All →</a>')
    expect(body.index("admin-nav")).to be < body.index("admin-banner--flags")
    expect(body.index("admin-banner--flags")).to be < body.index("ADMIN DASHBOARD")
  end
end
