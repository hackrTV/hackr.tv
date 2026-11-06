require "rails_helper"

# /root/analytics_dashboard — the analytics readout as a console screen
# (console-ui-for-all-admin Phase 6, 2026-11-04). The metrics service
# is stubbed: the screen is what is under test.
RSpec.describe "Admin analytics dashboard", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def stub_metrics!
    svc = instance_double(Analytics::GridMetricsService,
      user_metrics: {dau: 3, wau: 8, mau: 21, total: 40, new_30d: 5, returning_30d: 16},
      feature_usage: {top_rooms: [{name: "The Docks", count: 120}, {name: "Neon Alley", count: 44}], top_tracks: [],
                      breach_attempts: 17, breach_success_rate: 41.2, shop_buys: 9, shop_sells: 4, mission_accepted: 6, mission_completion_rate: 50.0},
      tutorial_funnel: {total_started: 12, completed: 4, drop_off_step: 3, step_counts: [[1, 12], [2, 10], [3, 5], [4, 4]]},
      session_metrics: {avg_duration_seconds: 754, total_sessions: 30, unique_users: 12, avg_sessions_per_user: 2.5},
      registrations_by_day: [{date: "2026-10-06", count: 2}, {date: "2026-10-07", count: 0}, {date: "2026-10-08", count: 5}],
      activity_by_day: [{date: "2026-10-06", count: 4}, {date: "2026-10-07", count: 4}, {date: "2026-10-08", count: 1}],
      analytics_event_count: 999, perf_summary: {total_metrics: 1234, web_vitals_24h: 56, slow_zone_renders_7d: 2})
    allow(Analytics::GridMetricsService).to receive(:new).and_return(svc)
    svc
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/analytics"

    expect(response).not_to have_http_status(:ok)
  end

  it "renders the tiles, the day charts as progress columns, the top ledgers, the funnel, sessions and telemetry" do
    stub_metrics!
    log_in!(admin)

    get "/root/analytics"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("// USERS //", ">3<", ">8<", ">21<", ">40<", "NEW 30D", "RETURNING 30D")
    expect(body).to include("// REGISTRATIONS · 3 DAYS · PEAK 5 //", '<progress value="2" max="5" title="2026-10-06: 2">', '<progress value="0" max="5"', "2026-10-06 to 2026-10-08")
    expect(body).to include("// DAILY ACTIVE · 3 DAYS · PEAK 4 //", '<progress value="4" max="4" title="2026-10-06: 4">')
    expect(body).to include("// TOP ROOMS //", "[01]", "The Docks", ">120<", "[02]", "Neon Alley", "// TOP TRACKS //", "NO DATA IN RANGE")
    expect(body).to include("// FEATURES //", "41.2%", "50.0%", "// TUTORIAL FUNNEL //", "STEP 3", 'title="step 3: 5 hackrs" class="rc-chart-drop"', 'title="step 1: 12 hackrs" class=""')
    expect(body).to include("// SESSIONS //", "12m", ">30<", "2.5", "// TELEMETRY //", ">1234<", ">56<", '<span class="rc-bad">2</span>', ">999<")
    expect(body).to include("[ERRORS]", "[FLAGS]", "[GUIDE]", "[RUNS]", "[ROOT]")
    expect(body).not_to include("[ANALYTICS]")
  end

  it "lights the chosen range and ignores an unknown one" do
    stub_metrics!
    log_in!(admin)

    get "/root/analytics", params: {range: "90"}
    expect(Analytics::GridMetricsService).to have_received(:new).with(range_days: 90)
    expect(response.body).to include('class="rc-btn rc-btn--on" aria-current="page" href="/root/analytics?range=90"')

    get "/root/analytics", params: {range: "nope"}
    expect(Analytics::GridMetricsService).to have_received(:new).with(range_days: 30)
    expect(response.body).to include('class="rc-btn rc-btn--on" aria-current="page" href="/root/analytics?range=30"')
  end
end
