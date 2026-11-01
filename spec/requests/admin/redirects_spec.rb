require "rails_helper"

# /root/redirects — the redirects ledger and the redirect record as
# console screens (console-ui-for-all-admin Phase 1, 2026-10-31).
RSpec.describe "Admin redirects", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/redirects"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the redirects as numbered ledger rows with the filter, destinations and the prompt" do
    create(:redirect, path: "/old", destination_url: "/new")
    create(:redirect, :xeraen)
    log_in!(admin)

    get "/root/redirects"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("2 redirects", "1 global · 1 per domain")
    expect(body).to include("[01]", "[02]", 'data-command="01"')
    expect(body).to include("every domain", "xeraen.com", "&gt; /new")
    expect(body).to include('data-search="xeraen.com / /xeraen"')
    expect(body).not_to include("[REDIRECTS]")
    expect(body).to include("[LOGS]", "type a redirect number")
  end

  it "redirects show to the record screen and renders the record with its delete form" do
    redirect = create(:redirect, path: "/old", destination_url: "/new", domain: "hackr.tv")
    log_in!(admin)

    get "/root/redirects/#{redirect.id}"
    expect(response).to redirect_to("/root/redirects/#{redirect.id}/edit")

    get "/root/redirects/#{redirect.id}/edit"
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include('value="/old"', 'value="/new"', 'value="hackr.tv"', %(action="/root/redirects/#{redirect.id}"))
    expect(body).to include('form="delete-redirect"', "Delete redirect &#39;/old&#39;?")
  end

  it "saves the record and stays on it, with a > in the reply" do
    redirect = create(:redirect, path: "/old", destination_url: "/new")
    log_in!(admin)

    patch "/root/redirects/#{redirect.id}", params: {redirect: {path: "/older", destination_url: "https://example.com", domain: "hackr.fm"}}

    expect(response).to redirect_to("/root/redirects/#{redirect.id}/edit")
    follow_redirect!
    expect(response.body).to be_console_clean
    expect(response.body).to include("[OK]", "Redirect updated: /older &gt; https://example.com")
    expect(redirect.reload).to have_attributes(path: "/older", destination_url: "https://example.com", domain: "hackr.fm")
  end

  it "re-renders a rejected save with a 422" do
    redirect = create(:redirect)
    log_in!(admin)

    patch "/root/redirects/#{redirect.id}", params: {redirect: {path: "", destination_url: ""}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "Failed to update redirect")
  end

  it "creates a redirect and opens its record, and deletes one" do
    log_in!(admin)

    get "/root/redirects/new"
    expect(response.body).to be_console_clean

    post "/root/redirects", params: {redirect: {path: "/fresh", destination_url: "/vault"}}
    created = Redirect.find_by!(path: "/fresh")
    expect(response).to redirect_to("/root/redirects/#{created.id}/edit")

    expect { delete "/root/redirects/#{created.id}" }.to change(Redirect, :count).by(-1)
    expect(response).to redirect_to("/root/redirects")
  end
end
