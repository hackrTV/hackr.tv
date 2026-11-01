require "rails_helper"

# /root/handbook_articles — the Hackr Handbook's articles ledger and the
# article record as console screens (console-ui-for-all-admin Phase 1,
# 2026-10-31).
RSpec.describe "Admin handbook articles", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:basics) { create(:handbook_section, name: "Basics", slug: "basics", position: 0) }
  let!(:economy) { create(:handbook_section, name: "Economy", slug: "economy", position: 1) }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/handbook_articles"

    expect(response).not_to have_http_status(:ok)
  end

  it "groups the articles by section, numbered through, with the section row, the filter and the prompt" do
    create(:handbook_article, :tutorial, handbook_section: basics, title: "Booting Up", slug: "booting-up")
    create(:handbook_article, :unpublished, handbook_section: economy, title: "CRED", slug: "cred")
    log_in!(admin)

    get "/root/handbook_articles"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("2 articles", "1 tutorial · 1 live · 2 sections")
    expect(body).to include("// BASICS //", "// ECONOMY //")
    expect(body).to include("[01]", "[02]", 'data-command="02"')
    expect(body).to include('data-ledger-filter-target="group"', 'data-search="booting up booting-up basics tutorial"')
    expect(body).to include("/root/handbook_articles?section_id=#{economy.id}")
    expect(body).to include("/root/handbook_articles/cred/edit", "/root/handbook_articles/cred/history")
    expect(body).not_to include("[ARTICLES]")
    expect(body).to include("type an article number")
  end

  it "narrows to one section" do
    create(:handbook_article, handbook_section: basics, title: "Booting Up")
    create(:handbook_article, handbook_section: economy, title: "CRED")
    log_in!(admin)

    get "/root/handbook_articles", params: {section_id: economy.id}

    expect(response.body).to include("CRED")
    expect(response.body).not_to include("Booting Up")
    expect(response.body).to include("/root/handbook_articles/new?section_id=#{economy.id}")
  end

  it "redirects show to the record screen" do
    create(:handbook_article, handbook_section: basics, slug: "booting-up")
    log_in!(admin)

    get "/root/handbook_articles/booting-up"

    expect(response).to redirect_to("/root/handbook_articles/booting-up/edit")
  end

  it "renders the record screen with the fields, the body, the metadata, the public link and the delete form" do
    create(:handbook_article, handbook_section: basics, title: "Booting Up", slug: "booting-up", metadata: {"search_tags" => ["boot"]})
    log_in!(admin)

    get "/root/handbook_articles/booting-up/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Booting Up"', 'action="/root/handbook_articles/booting-up"')
    expect(body).to include('name="handbook_article[handbook_section_id]"', 'name="handbook_article[kind]"', 'name="handbook_article[difficulty]"')
    expect(body).to include("// BODY (MARKDOWN) //", "// METADATA (JSON) //", "&quot;search_tags&quot;")
    expect(body).to include('href="/handbook/booting-up"', "/root/handbook_articles?section_id=#{basics.id}")
    expect(body).to include('form="delete-article"', 'id="delete-article"')
  end

  it "saves the record and stays on it; invalid metadata re-renders 422 against the saved slug" do
    article = create(:handbook_article, handbook_section: basics, slug: "booting-up")
    log_in!(admin)

    patch "/root/handbook_articles/booting-up", params: {handbook_article: {handbook_section_id: economy.id, title: "Booting", slug: "booting-up", kind: "tutorial", difficulty: "advanced", summary: "S", body: "B", position: "2", published: "0", metadata_json: '{"search_tags": ["x"]}'}}
    expect(response).to redirect_to("/root/handbook_articles/booting-up/edit")
    follow_redirect!
    expect(response.body).to include("[OK]")
    expect(article.reload).to have_attributes(handbook_section_id: economy.id, kind: "tutorial", difficulty: "advanced", body: "B", position: 2, published: false, metadata: {"search_tags" => ["x"]})

    patch "/root/handbook_articles/booting-up", params: {handbook_article: {title: "Booting", slug: "Bad Slug", metadata_json: "[1]"}}
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "must be a JSON object", 'action="/root/handbook_articles/booting-up"')
    expect(response.body).to match(%r{name="handbook_article\[metadata_json\]"[^>]*>\n?\[1\]</textarea>}) # the JSON as typed
  end

  it "prefills the section on new, creates an article and opens its record, and deletes one" do
    log_in!(admin)

    get "/root/handbook_articles/new", params: {section_id: economy.id}
    expect(response.body).to be_console_clean
    expect(response.body).to include(%(<option selected="selected" value="#{economy.id}">Economy</option>))

    post "/root/handbook_articles", params: {handbook_article: {handbook_section_id: economy.id, title: "Fresh Article", kind: "reference", position: "0", metadata_json: ""}}
    expect(response).to redirect_to("/root/handbook_articles/fresh-article/edit")

    expect { delete "/root/handbook_articles/fresh-article" }.to change(HandbookArticle, :count).by(-1)
    expect(response).to redirect_to("/root/handbook_articles?section_id=#{economy.id}")
  end
end
