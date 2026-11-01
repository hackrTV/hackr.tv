require "rails_helper"

# /root/hackr_logs — the logs ledger and the log record as console
# screens (console-ui-for-all-admin Phase 1, 2026-10-31).
RSpec.describe "Admin hackr logs", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/hackr_logs"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the logs as numbered ledger rows with the filter, destinations and the prompt" do
    create(:hackr_log, :published, title: "Signal Lost", slug: "signal-lost", grid_hackr: admin)
    create(:hackr_log, title: "Draft Line", slug: "draft-line", grid_hackr: admin)
    log_in!(admin)

    get "/root/hackr_logs"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 logs")
    expect(body).to include("1 live · 1 draft")
    expect(body).to include("[01]", "[02]", 'data-command="01"')
    expect(body).to include('data-search="signal lost signal-lost')
    expect(body).to include('data-ledger-filter-target="input"')
    expect(body).to include("/root/hackr_logs/signal-lost/edit", "/root/hackr_logs/signal-lost/history")
    expect(body).to include("LIVE", "DRAFT")
    expect(body).to include("[CODEX]", "[REDIRECTS]")
    expect(body).not_to include("[LOGS]")
    expect(body).to include("type a log number")
  end

  it "redirects show to the record screen" do
    create(:hackr_log, slug: "signal-lost")
    log_in!(admin)

    get "/root/hackr_logs/signal-lost"

    expect(response).to redirect_to("/root/hackr_logs/signal-lost/edit")
  end

  it "renders the record screen with the fields, the public link and the delete form" do
    create(:hackr_log, :published, title: "Signal Lost", slug: "signal-lost", timeline: "2120s", grid_hackr: admin)
    log_in!(admin)

    get "/root/hackr_logs/signal-lost/edit"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include('value="Signal Lost"', 'value="2120s"')
    expect(body).to include('action="/root/hackr_logs/signal-lost"')
    expect(body).to include("// BODY //", 'name="hackr_log[body]"')
    expect(body).to include('name="hackr_log[published_at]"', 'name="hackr_log[grid_hackr_id]"')
    expect(body).to include('href="/logs/signal-lost"')
    expect(body).to include('form="delete-log"', 'id="delete-log"', 'data-confirm="Delete log')
  end

  it "saves the record and stays on it" do
    log = create(:hackr_log, slug: "signal-lost", grid_hackr: admin)
    log_in!(admin)

    patch "/root/hackr_logs/signal-lost", params: {hackr_log: {title: "Signal Found", slug: "signal-lost", body: "New body", timeline: "2110s", published: "1", published_at: "2026-10-01T12:00", grid_hackr_id: operative.id}}

    expect(response).to redirect_to("/root/hackr_logs/signal-lost/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Hackr log 'Signal Found' updated."))
    expect(log.reload).to have_attributes(title: "Signal Found", body: "New body", timeline: "2110s", published: true, grid_hackr_id: operative.id)
    expect(log.published_at.to_date).to eq(Date.new(2026, 10, 1))
  end

  it "re-renders a rejected save against the saved slug" do
    create(:hackr_log, slug: "signal-lost")
    log_in!(admin)

    patch "/root/hackr_logs/signal-lost", params: {hackr_log: {title: "", slug: ""}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]")
    expect(response.body).to include('action="/root/hackr_logs/signal-lost"')
    expect(response.body).to include("/root/hackr_logs/signal-lost/history")
  end

  it "creates a log and opens its record, and renders the new screen" do
    log_in!(admin)

    get "/root/hackr_logs/new"
    expect(response.body).to be_console_clean
    expect(response.body).to include("[CREATE LOG]")

    expect {
      post "/root/hackr_logs", params: {hackr_log: {title: "Fresh", slug: "fresh", body: "x", timeline: "2120s", grid_hackr_id: admin.id}}
    }.to change(HackrLog, :count).by(1)
    expect(response).to redirect_to("/root/hackr_logs/fresh/edit")
  end

  it "deletes a log" do
    create(:hackr_log, slug: "signal-lost")
    log_in!(admin)

    expect { delete "/root/hackr_logs/signal-lost" }.to change(HackrLog, :count).by(-1)
    expect(response).to redirect_to("/root/hackr_logs")
  end
end
