require "rails_helper"

# /root/world_event_feed — the World Event Feed's settings, manual
# publish and recent events as a console screen (console-ui-for-all-admin
# Phase 1, 2026-10-31).
RSpec.describe "Admin world event feed", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/world_event_feed"

    expect(response).not_to have_http_status(:ok)
  end

  it "draws the status, the settings and publish forms, and the recent events" do
    simulant = create(:grid_hackr, hackr_alias: "ghostwire")
    WorldEventSimulant.create!(grid_hackr: simulant, state: {})
    WorldEvent.create!(event_type: "manual", hackr_alias: "ghostwire", data: {message: "hello grid"}, simulated: true)
    log_in!(admin)

    get "/root/world_event_feed"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("// STATUS //", "SIMULANTS", "// SETTINGS //", "// MANUAL PUBLISH //", "// RECENT EVENTS //")
    expect(body).to include('name="world_event_setting[target_events_per_minute]"', 'name="world_event_setting[simulator_enabled]"', 'name="world_event_setting[visible]"')
    expect(body).to include('name="event_type"', 'name="hackr_alias"', 'name="message"', 'name="mission_name"', '<option value="ghostwire">ghostwire</option>')
    expect(body).to include("@ghostwire", "SIM")
    expect(body).not_to include("[FEED]")
    expect(body).to include("[ALERTS]")
  end

  it "saves the settings and publishes an event as SYSTEM" do
    log_in!(admin)

    patch "/root/world_event_feed/settings", params: {world_event_setting: {target_events_per_minute: "20", simulator_enabled: "0", visible: "1"}}
    expect(response).to redirect_to("/root/world_event_feed")
    expect(WorldEventSetting.current).to have_attributes(target_events_per_minute: 20, simulator_enabled: false, visible: true)

    post "/root/world_event_feed/publish", params: {event_type: "manual", hackr_alias: "", message: "the grid hums"}
    follow_redirect!
    expect(response.body).to include("[OK]", "Event published: manual for SYSTEM", "SIMULATOR OFF")
  end
end
