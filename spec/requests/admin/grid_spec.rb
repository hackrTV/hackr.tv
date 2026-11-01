require "rails_helper"

# /root/grid — the PULSE GRID operator screen as a console
# (console-ui-for-all-admin Phase 2, 2026-10-31): broadcast, who is
# online, the recent room messages and every hackr with grid access /
# login / service-account controls.
RSpec.describe "Admin grid", type: :request do
  let!(:room) { create(:grid_room, name: "Neon Alley") }
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, hackr_alias: "ghostline", password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid"

    expect(response).not_to have_http_status(:ok)
  end

  it "draws the broadcast form, the online hackrs, the recent messages and the hackrs ledger with its controls" do
    log_in!(admin)
    operative.update!(current_room: room, last_activity_at: Time.current)
    create(:grid_message, grid_hackr: operative, room: room, content: "anyone copy?")
    create(:grid_message, :system, grid_hackr: admin, room: room, content: "[SYSTEM BROADCAST] maintenance at dawn")
    svc = create(:grid_hackr, hackr_alias: "relaybot", service_account: true, login_disabled: true)
    create(:feature_grant, grid_hackr: svc, feature: FeatureGrant::PULSE_GRID)

    get "/root/grid"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("PULSE GRID", "// BROADCAST //", 'name="message"', "[BROADCAST]", 'data-confirm="Send broadcast to all rooms?"')
    expect(body).to include("// ONLINE · 1 //", "Neon Alley", "##{room.id}")
    expect(body).to include("// RECENT MESSAGES //", "&lt;ghostline&gt;", "anyone copy?", "[SYSTEM]", "maintenance at dawn")
    expect(body).to include("// HACKRS · 3 //", "SERVICE ACCOUNT", "GRANTED", "DISABLED")
    expect(body).to include(%(href="/root/grid_hackrs/#{operative.id}"), 'data-command="01"', 'data-command="04"')
    expect(body).to include(%(action="/root/grid/grant_feature?feature=pulse_grid&amp;hackr_id=#{operative.id}"))
    expect(body).to include(%(action="/root/grid/revoke_feature?feature=pulse_grid&amp;hackr_id=#{svc.id}"))
    expect(body).to include(%(action="/root/grid/hackrs/#{svc.id}/enable_login"), %(action="/root/grid/hackrs/#{operative.id}/disable_login"))
    expect(body).not_to include(%(action="/root/grid/hackrs/#{admin.id}/disable_login"))
    expect(body).to include(%(action="/root/grid/hackrs/#{svc.id}/toggle_service_account"), "[x] SVC", "[SVC]")
    expect(body).to include("[WIRE]", "[UPLINK]").and include("a hackr number")
    expect(body).not_to include("[GRID]")
  end

  it "reads NOW from the online set: a hackr idle past 15 minutes is OFF even with a room" do
    log_in!(admin)
    operative.update!(current_room: room, last_activity_at: 20.minutes.ago)

    get "/root/grid"

    body = response.body
    expect(body).to include("// ONLINE · 0 //", "NO HACKRS ONLINE")
    row = body[%r{href="/root/grid_hackrs/#{operative.id}".*?rc-links}m]
    expect(row).to include(">OFF</span>")
    expect(row).not_to include(">ON</span>")
  end

  it "broadcasts to every room, and refuses an empty one" do
    log_in!(admin)

    post "/root/grid/broadcast", params: {message: "   "}
    follow_redirect!
    expect(response.body).to include("[ERR]", "Broadcast message cannot be empty!")

    post "/root/grid/broadcast", params: {message: "maintenance at dawn"}
    follow_redirect!
    expect(response.body).to include("[OK]", "Broadcast sent to all rooms!", "[SYSTEM BROADCAST] maintenance at dawn")
  end

  it "grants and revokes grid access" do
    log_in!(admin)

    post "/root/grid/grant_feature", params: {hackr_id: operative.id, feature: FeatureGrant::PULSE_GRID}
    follow_redirect!
    expect(response.body).to include("[OK]", "Granted &#39;pulse_grid&#39; access to ghostline.")
    expect(response.body).to include(%(action="/root/grid/revoke_feature?feature=pulse_grid&amp;hackr_id=#{operative.id}"))

    delete "/root/grid/revoke_feature", params: {hackr_id: operative.id, feature: FeatureGrant::PULSE_GRID}
    expect(operative.feature_grants.reload).to be_empty
  end
end
