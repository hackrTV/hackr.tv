require "rails_helper"

# /root/error_groups — the error tracker's ledger and group readout as
# console screens (console-ui-for-all-admin Phase 6, 2026-11-04).
RSpec.describe "Admin error groups", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def group!(title, **attrs)
    ErrorGroup.create!({fingerprint: Digest::SHA1.hexdigest(title), title: title, component: "backend", severity: "error",
                        first_seen_at: 2.days.ago, last_seen_at: 1.hour.ago, occurrence_count: 3}.merge(attrs))
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/error_groups"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the groups numbered with the filter rows, actions, destinations and the prompt" do
    open = group!("NoMethodError in GridController#show")
    ignored = group!("TypeError in the HUD", component: "frontend", status: "ignored", ignore_until: 1.day.from_now)
    ErrorOccurrence.create!(error_group: open, component: "backend", message: "boom", occurred_at: 10.minutes.ago)
    log_in!(admin)

    get "/root/error_groups"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 error groups", "[01]", "[02]", "NoMethodError in GridController#show", "/root/error_groups/#{open.id}",
      'data-command="01"', 'data-command="02"', "BACKEND", "FRONTEND", "IGNORED", "until #{ignored.ignore_until.strftime("%m-%d %H:%M")}")
    expect(body).to include("/root/error_groups/#{open.id}/resolve", "/root/error_groups/#{open.id}/ignore?duration=24h", "/root/error_groups/#{ignored.id}/reopen")
    expect(body).to include('id="search"', "/root/error_groups?status=resolved", "/root/error_groups?component=frontend", "/root/error_groups?severity=warning")
    expect(body).to include("[FLAGS]", "[ANALYTICS]", "[GUIDE]", "[RUNS]", "[ROOT]")
    expect(body).not_to include("[ERRORS]")
    expect(body).to include("type a group number")
  end

  it "narrows by status, component, severity and search, keeps the others in the links, and ignores unknown values" do
    group!("alpha backend", component: "backend")
    group!("beta frontend", component: "frontend", severity: "warning")
    group!("gamma resolved", status: "resolved")
    log_in!(admin)

    get "/root/error_groups", params: {component: "frontend", search: "beta"}
    body = response.body
    expect(body).to include("1 error group", "filtered", "beta frontend", 'value="beta"')
    expect(body).not_to include("alpha backend", "gamma resolved")
    expect(body).to include("/root/error_groups?component=frontend&amp;search=beta&amp;status=open")
    expect(body[/<input type="hidden" name="component"[^>]*>/]).to include('value="frontend"')

    get "/root/error_groups", params: {status: "resolved"}
    expect(response.body).to include("1 error group", "gamma resolved")

    get "/root/error_groups", params: {component: "frontend"}
    expect(response.body).to include("1 error group", "beta frontend")
    expect(response.body).not_to include("alpha backend")

    get "/root/error_groups", params: {severity: "warning"}
    expect(response.body).to include("1 error group", "beta frontend")
    expect(response.body).not_to include("gamma resolved")

    get "/root/error_groups", params: {status: "bogus", severity: ["x"], search: ["y"]}
    expect(response.body).to include("3 error groups")
    expect(response.body).not_to include('name="status"', 'name="severity"')
  end

  it "clamps a stale offset to the last page" do
    group!("only one")
    log_in!(admin)

    get "/root/error_groups", params: {status: "open", offset: 50}

    expect(response.body).to include("1 error group", "only one")
    expect(response.body).not_to include("NO ERROR GROUPS MATCH")
  end

  it "pages the ledger past 50 groups" do
    55.times { |i| group!("error #{i}") }
    log_in!(admin)

    get "/root/error_groups"
    expect(response.body).to include("1–50 of 55", "/root/error_groups?offset=50", "[50]")
    expect(response.body).not_to include("[51]")

    get "/root/error_groups", params: {offset: 50}
    expect(response.body).to include("51–55 of 55", "[05]")
  end

  it "shows a group's readout with its actions and paged occurrences" do
    group = group!("ArgumentError in BreachService", occurrence_count: 51)
    51.times do |i|
      ErrorOccurrence.create!(error_group: group, component: "backend", exception_class: "ArgumentError", message: "bad arg #{i}",
        occurred_at: i.minutes.ago, hackr_alias: "runner", ip_address: "10.0.0.#{i}", request_method: "POST", request_url: "/grid/breach",
        backtrace: ["app/services/breach.rb:10", "app/controllers/grid.rb:5"].to_json, metadata: {"zone" => "docks"}.to_json, request_params: {"id" => i}.to_json)
    end
    log_in!(admin)

    get "/root/error_groups/#{group.id}"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("ERROR ##{group.id}", "ArgumentError in BreachService", "OPEN", "BACKEND", "ERROR", "51", group.fingerprint)
    expect(body).to include("[RESOLVE]", "[IGNORE 1H]", "[IGNORE 24H]", "[IGNORE 7D]", "[IGNORE FOREVER]", "/root/error_groups/#{group.id}/ignore?duration=forever")
    expect(body).to include("// OCCURRENCES · 51 //", "bad arg 0", "@runner", "10.0.0.0", "POST /grid/breach", "BACKTRACE", "2 frames", "app/services/breach.rb:10", "METADATA", "&quot;zone&quot;: &quot;docks&quot;", "PARAMS")
    expect(body).to include("1–50 of 51", "/root/error_groups/#{group.id}?offset=50")
    expect(body).not_to include("bad arg 50")
    expect(body).to include("[&lt;] ERRORS", 'data-command="back"', "[FLAGS]")
    expect(body).not_to include("[ERRORS]")
  end

  it "resolves, ignores and reopens, landing back where the button was" do
    group = group!("resolve me")
    log_in!(admin)

    post "/root/error_groups/#{group.id}/resolve", headers: {"HTTP_REFERER" => "http://www.example.com/root/error_groups/#{group.id}"}
    expect(response).to redirect_to("http://www.example.com/root/error_groups/#{group.id}")
    follow_redirect!
    expect(response.body).to include("[OK]", "Error group resolved.", "RESOLVED", admin.hackr_alias, "[REOPEN]")
    expect(group.reload.status).to eq("resolved")
    expect(group.resolved_by_hackr).to eq(admin)

    post "/root/error_groups/#{group.id}/reopen"
    expect(response).to redirect_to("/root/error_groups")
    expect(group.reload.status).to eq("open")

    post "/root/error_groups/#{group.id}/ignore", params: {duration: "7d"}, headers: {"HTTP_REFERER" => "http://www.example.com/root/error_groups?status=open"}
    expect(response).to redirect_to("http://www.example.com/root/error_groups?status=open")
    follow_redirect!
    expect(response.body).to include("[OK]", "Error group ignored until")
    expect(group.reload.status).to eq("ignored")
    expect(group.ignore_until).to be_within(1.minute).of(7.days.from_now)
  end
end
