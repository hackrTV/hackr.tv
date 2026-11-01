require "rails_helper"

# /root/handbook_sections — the Hackr Handbook's sections ledger and the
# section record (with its articles) as console screens
# (console-ui-for-all-admin Phase 1, 2026-10-31).
RSpec.describe "Admin handbook sections", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/handbook_sections"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the sections in handbook order with their article counts, destinations and the prompt" do
    basics = create(:handbook_section, name: "Basics", slug: "basics", position: 0)
    create(:handbook_section, :unpublished, name: "Economy", slug: "economy", position: 1)
    create(:handbook_article, handbook_section: basics)
    log_in!(admin)

    get "/root/handbook_sections"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("2 sections", "1 article")
    expect(body).to include("[01]", "[02]", 'data-command="01"')
    expect(body.index("/root/handbook_sections/basics/edit")).to be < body.index("/root/handbook_sections/economy/edit")
    expect(body).to include("LIVE", "DRAFT")
    expect(body).to include("/root/handbook_articles?section_id=#{basics.id}")
    expect(body).to include("/root/handbook_sections/basics/edit", "/root/handbook_sections/basics/history")
    expect(body).not_to include("[SECTIONS]")
    expect(body).to include("type a section number")
  end

  it "redirects show to the record screen" do
    create(:handbook_section, slug: "basics")
    log_in!(admin)

    get "/root/handbook_sections/basics"

    expect(response).to redirect_to("/root/handbook_sections/basics/edit")
  end

  it "renders the record screen with the fields, its articles ledger and the delete form" do
    section = create(:handbook_section, name: "Basics", slug: "basics", icon: ">>")
    create(:handbook_article, handbook_section: section, title: "Booting Up", slug: "booting-up", position: 1)
    create(:handbook_article, :tutorial, handbook_section: section, title: "First Steps", slug: "first-steps", position: 0)
    log_in!(admin)

    get "/root/handbook_sections/basics/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Basics"', 'value="&gt;&gt;"', 'action="/root/handbook_sections/basics"')
    expect(body).to include("// ARTICLES //", "TUTORIAL", "/root/handbook_articles/booting-up/edit")
    expect(body.index("/root/handbook_articles/first-steps/edit")).to be < body.index("/root/handbook_articles/booting-up/edit")
    expect(body).to include("/root/handbook_articles/new?section_id=#{section.id}")
    expect(body).to include('form="delete-section"', "and its 2 articles?")
  end

  it "saves the record and stays on it; a rejected save re-renders against the saved slug" do
    section = create(:handbook_section, slug: "basics")
    log_in!(admin)

    patch "/root/handbook_sections/basics", params: {handbook_section: {name: "Basics II", slug: "basics", icon: "%%", position: "4", published: "0", summary: "Start"}}
    expect(response).to redirect_to("/root/handbook_sections/basics/edit")
    follow_redirect!
    expect(response.body).to include("[OK]")
    expect(section.reload).to have_attributes(name: "Basics II", icon: "%%", position: 4, published: false, summary: "Start")

    patch "/root/handbook_sections/basics", params: {handbook_section: {name: "", slug: "Bad Slug"}}
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", 'action="/root/handbook_sections/basics"')
  end

  it "creates a section and opens its record, and deletes one" do
    log_in!(admin)

    get "/root/handbook_sections/new"
    expect(response.body).to be_console_clean

    post "/root/handbook_sections", params: {handbook_section: {name: "Fresh Section", position: "0"}}
    expect(response).to redirect_to("/root/handbook_sections/fresh-section/edit")

    expect { delete "/root/handbook_sections/fresh-section" }.to change(HandbookSection, :count).by(-1)
    expect(response).to redirect_to("/root/handbook_sections")
  end
end
