require "rails_helper"

# /root/overlays (the HUD's data surface + now playing) and
# /root/overlays/alerts (the alert queue) as console screens
# (console-ui-for-all-admin Phase 1, 2026-10-31). Behavior of the
# now-playing writes: spec/controllers/admin/overlays_controller_spec.rb.
RSpec.describe "Admin overlays", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)

    get "/root/overlays"
    expect(response).not_to have_http_status(:ok)
    get "/root/overlays/alerts"
    expect(response).not_to have_http_status(:ok)
  end

  it "draws the overlays screen: now playing, pending alerts and the HUD data surface" do
    track = create(:track, title: "Neon Rain")
    OverlayNowPlaying.set_track!(track, paused: true)
    create(:overlay_alert, :pending)
    log_in!(admin)

    get "/root/overlays"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("// NOW PLAYING //", "Neon Rain", "PAUSED", "1 alert")
    expect(body).to include("// HUD DATA SURFACE //", "GET /api/overlay/alerts/pending", "OverlayChannel")
    expect(body).to include('data-command="playing"', "[ALERTS]")
    expect(body).not_to include("[OVERLAYS]")
  end

  it "draws the now-playing editor with the set rows and the hidden clear form" do
    create(:track, title: "Neon Rain")
    log_in!(admin)

    get "/root/overlays/now-playing/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("NOTHING PLAYING", 'name="overlay_now_playing[track_id]"', "Neon Rain")
    expect(body).to include('name="overlay_now_playing[custom_title]"', 'name="overlay_now_playing[custom_artist]"', 'name="overlay_now_playing[paused]"')
    expect(body).to include('form="clear-now-playing"', 'id="clear-now-playing"', 'data-confirm="Clear now playing?"', 'name="clear"')
  end

  it "lists the alerts newest first with the type row and a delete per row" do
    old = create(:overlay_alert, :displayed, title: "Old One", created_at: 1.hour.ago)
    create(:overlay_alert, :raid, :pending)
    log_in!(admin)

    get "/root/overlays/alerts"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("2 alerts", "1 pending", "[01]", "[02]", 'data-command="02"')
    expect(body.index("Incoming Raid!")).to be < body.index("Old One")
    expect(body).to include("DISPLAYED", "PENDING", "/root/overlays/alerts?alert_type=raid")
    expect(body).to include(%(action="/root/overlays/alerts/#{old.id}"), 'data-confirm="Delete this alert?"')

    get "/root/overlays/alerts", params: {alert_type: "raid"}
    expect(response.body).not_to include("Old One")
  end

  it "shows one alert with its data and a delete form" do
    alert = create(:overlay_alert, title: "Big Raid", data: {"viewers" => 42})
    log_in!(admin)

    get "/root/overlays/alerts/#{alert.id}"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("Big Raid", "CUSTOM", "// DATA //", "&quot;viewers&quot;: 42")
    expect(body).to include('form="delete-alert"', 'id="delete-alert"')
  end

  it "sends an alert from the new screen, warning on invalid JSON" do
    log_in!(admin)

    get "/root/overlays/alerts/new"
    expect(response.body).to be_console_clean
    expect(response.body).to include('name="overlay_alert[data_json]"', 'name="overlay_alert[alert_type]"')

    expect {
      post "/root/overlays/alerts", params: {overlay_alert: {alert_type: "follow", title: "Hi", message: "Yo", data_json: "{bad"}}
    }.to change(OverlayAlert, :count).by(1)
    expect(response).to redirect_to("/root/overlays/alerts")
    follow_redirect!
    expect(response.body).to include("[OK]", "[WARN]", "Alert data JSON was invalid")
  end
end
