require "rails_helper"

# /root/codex_entries — the codex ledger and the entry record as console
# screens (console-ui-for-all-admin Phase 1, 2026-10-31).
RSpec.describe "Admin codex entries", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/codex_entries"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the entries as numbered ledger rows with the type row, the filter, destinations and the prompt" do
    create(:codex_entry, :published, name: "GovCorp", slug: "govcorp", entry_type: "organization", summary: "The Gov")
    create(:codex_entry, name: "XERAEN", slug: "xeraen", entry_type: "person")
    log_in!(admin)

    get "/root/codex_entries"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 entries", "1 live · 1 draft")
    expect(body).to include("[01]", "[02]", 'data-command="02"')
    expect(body).to include('data-search="govcorp govcorp the gov organization"')
    expect(body).to include("ORGANIZATION", "PERSON")
    expect(body).to include("/root/codex_entries?entry_type=concept")
    expect(body).to include("/root/codex_entries/govcorp/edit", "/root/codex_entries/govcorp/history")
    expect(body).to include("[LOGS]", "[ARTICLES]")
    expect(body).not_to include("[CODEX]")
    expect(body).to include("type an entry number")
  end

  it "narrows the ledger to one type and marks it" do
    create(:codex_entry, name: "GovCorp", slug: "govcorp", entry_type: "organization")
    create(:codex_entry, name: "XERAEN", slug: "xeraen", entry_type: "person")
    log_in!(admin)

    get "/root/codex_entries", params: {entry_type: "person"}

    expect(response.body).to include("XERAEN")
    expect(response.body).not_to include("GovCorp")
    expect(response.body).to include('class="rc-btn rc-btn--on" aria-current="page" href="/root/codex_entries?entry_type=person"')
  end

  it "ignores an unknown or malformed type filter" do
    create(:codex_entry, name: "GovCorp", slug: "govcorp", entry_type: "organization")
    log_in!(admin)

    get "/root/codex_entries", params: {entry_type: "bogus"}
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("GovCorp")
    expect(response.body).not_to include("BOGUS")
    expect(response.body).to include('class="rc-btn rc-btn--on" aria-current="page" href="/root/codex_entries"')

    get "/root/codex_entries?entry_type[]=person"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("GovCorp")
  end

  it "redirects show to the record screen" do
    create(:codex_entry, slug: "govcorp")
    log_in!(admin)

    get "/root/codex_entries/govcorp"

    expect(response).to redirect_to("/root/codex_entries/govcorp/edit")
  end

  it "renders the record screen with the fields, the metadata JSON, the public link and the delete form" do
    create(:codex_entry, :published, name: "GovCorp", slug: "govcorp", metadata: {"founded" => 2099})
    log_in!(admin)

    get "/root/codex_entries/govcorp/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="GovCorp"', 'action="/root/codex_entries/govcorp"')
    expect(body).to include("// SUMMARY //", "// CONTENT //", "// METADATA //")
    expect(body).to include('name="codex_entry[metadata_json]"', "&quot;founded&quot;: 2099")
    expect(body).to include('href="/codex/govcorp"')
    expect(body).to include('form="delete-entry"', 'id="delete-entry"')
  end

  it "saves the record with its metadata and stays on it" do
    entry = create(:codex_entry, slug: "govcorp")
    log_in!(admin)

    patch "/root/codex_entries/govcorp", params: {codex_entry: {name: "GovCorp", slug: "govcorp", entry_type: "faction", summary: "S", content: "C", position: "3", published: "1", metadata_json: '{"tier": 1}'}}

    expect(response).to redirect_to("/root/codex_entries/govcorp/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Codex entry 'GovCorp' updated."))
    expect(entry.reload).to have_attributes(entry_type: "faction", summary: "S", content: "C", position: 3, published: true, metadata: {"tier" => 1})
  end

  it "rejects invalid metadata JSON with a 422 against the saved slug" do
    create(:codex_entry, slug: "govcorp")
    log_in!(admin)

    patch "/root/codex_entries/govcorp", params: {codex_entry: {name: "GovCorp", slug: "Bad Slug", metadata_json: "{nope"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "is not valid JSON")
    expect(response.body).to include('action="/root/codex_entries/govcorp"')
    expect(response.body).to match(%r{name="codex_entry\[metadata_json\]"[^>]*>\n?\{nope</textarea>}) # the JSON as typed, not the stored {}
  end

  it "creates an entry and opens its record, and deletes one" do
    log_in!(admin)

    get "/root/codex_entries/new"
    expect(response.body).to be_console_clean

    post "/root/codex_entries", params: {codex_entry: {name: "Fresh Entry", entry_type: "concept", metadata_json: ""}}
    expect(response).to redirect_to("/root/codex_entries/fresh-entry/edit")

    expect { delete "/root/codex_entries/fresh-entry" }.to change(CodexEntry, :count).by(-1)
    expect(response).to redirect_to("/root/codex_entries")
  end
end
