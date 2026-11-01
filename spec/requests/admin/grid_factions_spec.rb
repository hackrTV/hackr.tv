require "rails_helper"

# /root/grid_factions — the factions ledger (+ the rep-link graph) and the
# faction record as console screens (console-ui-for-all-admin Phase 3,
# 2026-10-31).
RSpec.describe "Admin grid factions", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_factions"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the factions and the rep-link graph form with destinations and the prompt" do
    parent = create(:grid_faction, name: "The Fracture", slug: "fracture", position: 1)
    child = create(:grid_faction, name: "Cell Nine", slug: "cell-nine", kind: "individual", parent: parent, position: 2)
    create(:grid_faction_rep_link, source_faction: parent, target_faction: child, weight: 0.5)
    log_in!(admin)

    get "/root/grid_factions"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 factions", "1 rep link", "[01]", "[02]", 'data-command="02"', "INDIVIDUAL", "POS 2")
    expect(body).to include("/root/grid_factions/#{child.id}/edit", "/root/grid_factions/#{child.id}/history")
    expect(body).to include("[&gt;] REPLOG", "[&gt;] REPUTATIONS", "// REP LINKS //", 'action="/root/grid_factions/update_rep_links"')
    expect(body).to include('name="rep_links[0][source_slug]"', '<option selected="selected" value="fracture">', 'name="rep_links[0][weight]"', 'value="0.5"')
    expect(body).to include('name="rep_links[3][target_slug]"').and(satisfy { |b| !b.include?('name="rep_links[4]') })
    expect(body).to include("[ROOMS]", "[TRANSIT]")
    expect(body).not_to include("[FACTIONS]")
    expect(body).to include("type a faction number")
  end

  it "replaces the rep-link graph from the form" do
    a = create(:grid_faction, slug: "a")
    b = create(:grid_faction, slug: "b")
    create(:grid_faction_rep_link, source_faction: b, target_faction: a, weight: 1.0)
    log_in!(admin)

    post "/root/grid_factions/update_rep_links", params: {rep_links: {"0" => {source_slug: "a", target_slug: "b", weight: "0.25"}, "1" => {source_slug: "", target_slug: "", weight: ""}}}

    expect(response).to redirect_to("/root/grid_factions")
    follow_redirect!
    expect(response.body).to include("[OK]", "Rep-link graph updated (1 link).")
    expect(GridFactionRepLink.pluck(:source_faction_id, :target_faction_id, :weight)).to eq([[a.id, b.id, 0.25]])
  end

  it "redirects show to the record screen" do
    faction = create(:grid_faction)
    log_in!(admin)

    get "/root/grid_factions/#{faction.id}"

    expect(response).to redirect_to("/root/grid_factions/#{faction.id}/edit")
  end

  it "renders the record with the fields, its rep links and the delete form" do
    faction = create(:grid_faction, name: "The Fracture")
    other = create(:grid_faction, name: "GovCorp")
    create(:grid_faction_rep_link, source_faction: faction, target_faction: other, weight: -0.5)
    log_in!(admin)

    get "/root/grid_factions/#{faction.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="The Fracture"', "action=\"/root/grid_factions/#{faction.id}\"", 'name="grid_faction[kind]"', 'name="grid_faction[parent_id]"', 'name="grid_faction[artist_id]"')
    expect(body).to include("SHIFTS", "GovCorp x-0.5", "SHIFTED BY")
    expect(body).to include('form="delete-faction"', 'id="delete-faction"')
  end

  it "saves every field and stays on the record" do
    faction = create(:grid_faction)
    parent = create(:grid_faction)
    artist = create(:artist)
    log_in!(admin)

    patch "/root/grid_factions/#{faction.id}", params: {grid_faction: {name: "Fracture", slug: "fracture-x", description: "D", color_scheme: "cyan", kind: "system", position: "5",
                                                                       parent_id: parent.id, artist_id: artist.id}}

    expect(response).to redirect_to("/root/grid_factions/#{faction.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Faction 'Fracture' updated."))
    expect(faction.reload).to have_attributes(name: "Fracture", slug: "fracture-x", description: "D", color_scheme: "cyan", kind: "system", position: 5,
      parent_id: parent.id, artist_id: artist.id)
  end

  it "rejects a duplicate slug with a 422 and the error on the field" do
    create(:grid_faction, slug: "taken")
    faction = create(:grid_faction, name: "The Fracture")
    log_in!(admin)

    patch "/root/grid_factions/#{faction.id}", params: {grid_faction: {slug: "taken"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "has already been taken", '<h1 class="console-bar-title">The Fracture</h1>')
  end

  it "creates a faction and opens its record; deletes one" do
    log_in!(admin)

    get "/root/grid_factions/new"
    expect(response.body).to be_console_clean

    post "/root/grid_factions", params: {grid_faction: {name: "Fresh", slug: "fresh", kind: "collective", position: "0"}}
    faction = GridFaction.find_by!(slug: "fresh")
    expect(response).to redirect_to("/root/grid_factions/#{faction.id}/edit")

    expect { delete "/root/grid_factions/#{faction.id}" }.to change(GridFaction, :count).by(-1)
    expect(response).to redirect_to("/root/grid_factions")
  end
end
