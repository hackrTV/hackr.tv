require "rails_helper"

# /root/grid_missions — the missions ledger and the mission record
# (pickers, objective / reward rows) as console screens
# (console-ui-for-all-admin Phase 4, 2026-11-01).
RSpec.describe "Admin grid missions", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:giver) { create(:grid_mob, :quest_giver, name: "AXIOM") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_missions"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the missions as numbered ledger rows with the filter, counts, destinations and the prompt" do
    arc = create(:grid_mission_arc, name: "The Fracture")
    first = create(:grid_mission, name: "First Contact", slug: "first-contact", giver_mob: giver, grid_mission_arc: arc, min_clearance: 3)
    create(:grid_mission_objective, grid_mission: first)
    create(:grid_hackr_mission, grid_mission: first, grid_hackr: operative)
    create(:grid_mission, :repeatable, :unpublished, name: "Daily Sweep", slug: "daily-sweep", giver_mob: giver, prereq_mission: first)
    log_in!(admin)

    get "/root/grid_missions"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 missions", "1 live", "1 repeatable", "1 active")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="first contact first-contact the fracture axiom"', 'data-search="daily sweep daily-sweep axiom first-contact"')
    expect(body).to include("after first-contact", "DRAFT", "REP", "/root/grid_missions/first-contact/edit", "/root/grid_missions/first-contact/history")
    expect(body).to include("/root/grid_missions/new", "/root/grid_mission_wizard/new", "[ARCS]", "[WIZARD]")
    expect(body).not_to include("[MISSIONS]")
    expect(body).to include("type a mission number")
  end

  it "redirects show to the record screen" do
    mission = create(:grid_mission, slug: "first-contact", giver_mob: giver)
    log_in!(admin)

    get "/root/grid_missions/#{mission.slug}"

    expect(response).to redirect_to("/root/grid_missions/first-contact/edit")
  end

  it "renders the record with the fields, the pickers, the rows and one blank row of each, and the script hooks" do
    arc = create(:grid_mission_arc, name: "The Fracture")
    mission = create(:grid_mission, name: "First Contact", slug: "first-contact", giver_mob: giver, grid_mission_arc: arc, dialogue_path: ["work", "job"])
    create(:grid_mission_objective, grid_mission: mission, position: 1, label: "Reach the docks")
    create(:grid_mission_reward, grid_mission: mission, position: 1, reward_type: "xp", amount: 50)
    log_in!(admin)

    get "/root/grid_missions/first-contact/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="First Contact"', 'action="/root/grid_missions/first-contact"', 'id="mission-form"')
    %w[slug name min_clearance min_rep_faction_id min_rep_value position repeatable published description dialogue_path_json giver_mob_id grid_mission_arc_id prereq_mission_id].each do |field|
      expect(body).to include(%(name="grid_mission[#{field}]"))
    end
    %w[giver-cb arc-cb prereq-cb].each do |key|
      %w[input hidden dropdown status].each { |part| expect(body).to include(%(id="#{key}-#{part}")) }
    end
    expect(body).to include(%(id="giver-cb-hidden" value="#{giver.id}"), "AXIOM @ ", %(id="arc-cb-hidden" value="#{arc.id}"))
    expect(body).to include(ERB::Util.html_escape('["work","job"]'), "[&gt;] AXIOM", "[&gt;] THE FRACTURE", "HACKRS")
    expect(body).to include('id="objectives-rows"', 'id="rewards-rows"', "data-row-remove", 'value="Reach the docks"')
    expect(body).to include('name="grid_mission[grid_mission_objectives_attributes][0][_destroy]"', 'name="grid_mission[grid_mission_objectives_attributes][1][label]"')
    expect(body).not_to include('name="grid_mission[grid_mission_objectives_attributes][1][_destroy]"')
    expect(body).to include('name="grid_mission[grid_mission_rewards_attributes][0][_destroy]"', 'name="grid_mission[grid_mission_rewards_attributes][1][reward_type]"')
    expect(body).to include("AdminCombobox.init", "giver-cb-input", "data-row-remove", "_destroy")
    expect(body).to include('form="delete-mission"', 'id="delete-mission"')
    script = body[/document\.getElementById\('mission-form'\).*?<\/script>/m]
    expect(script).to include("prereq-cb-input")
    expect(script).not_to include("tui-", "cssText", "onclick")
  end

  it "prefills the arc of a new mission" do
    arc = create(:grid_mission_arc, name: "The Fracture")
    log_in!(admin)

    get "/root/grid_missions/new", params: {grid_mission_arc_id: arc.id}

    expect(response.body).to be_console_clean
    expect(response.body).to include(%(id="arc-cb-hidden" value="#{arc.id}"), 'value="The Fracture"', "[&gt;] WIZARD")
  end

  it "saves every field, edits and removes rows, adds one from the blank row, skips an untouched blank row and stays on the record" do
    mission = create(:grid_mission, slug: "first-contact", giver_mob: giver)
    objective = create(:grid_mission_objective, grid_mission: mission, position: 1)
    reward = create(:grid_mission_reward, grid_mission: mission, position: 1, reward_type: "xp", amount: 50)
    other_giver = create(:grid_mob, :vendor)
    arc = create(:grid_mission_arc)
    prereq = create(:grid_mission, giver_mob: giver)
    faction = create(:grid_faction)
    log_in!(admin)

    patch "/root/grid_missions/first-contact", params: {grid_mission: {
      slug: "second-contact", name: "Second Contact", description: "D", giver_mob_id: other_giver.id, grid_mission_arc_id: arc.id,
      prereq_mission_id: prereq.id, min_clearance: "4", min_rep_faction_id: faction.id, min_rep_value: "20", position: "9",
      repeatable: "1", published: "1", dialogue_path_json: '["work"]',
      grid_mission_objectives_attributes: {
        "0" => {id: objective.id, position: "2", objective_type: "talk_npc", label: "Talk to AXIOM", target_slug: "AXIOM", target_count: "1", _destroy: "0"},
        "1" => {position: "3", objective_type: "collect_item", label: "Grab the chip", target_slug: "data chip", target_count: "2"}
      },
      grid_mission_rewards_attributes: {
        "0" => {id: reward.id, position: "1", reward_type: "xp", amount: "50", target_slug: "", quantity: "1", _destroy: "1"},
        "1" => {position: "2", reward_type: "", amount: "0", target_slug: "", quantity: "1"}
      }
    }}

    expect(response).to redirect_to("/root/grid_missions/second-contact/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Mission 'Second Contact' updated."))
    expect(mission.reload).to have_attributes(slug: "second-contact", name: "Second Contact", description: "D", giver_mob_id: other_giver.id,
      grid_mission_arc_id: arc.id, prereq_mission_id: prereq.id, min_clearance: 4, min_rep_faction_id: faction.id, min_rep_value: 20,
      position: 9, repeatable: true, published: true, dialogue_path: ["work"])
    expect(mission.grid_mission_objectives.map { |o| [o.position, o.objective_type, o.label, o.target_slug, o.target_count] })
      .to eq([[2, "talk_npc", "Talk to AXIOM", "AXIOM", 1], [3, "collect_item", "Grab the chip", "data chip", 2]])
    expect(mission.grid_mission_rewards).to be_empty
  end

  it "rejects a published mission with no giver with a 422, the error on the GIVER row and a removed row still hidden" do
    mission = create(:grid_mission, slug: "first-contact", giver_mob: giver)
    reward = create(:grid_mission_reward, grid_mission: mission, reward_type: "cred", amount: 5, position: 1)
    log_in!(admin)

    patch "/root/grid_missions/first-contact", params: {grid_mission: {giver_mob_id: "", published: "1", dialogue_path_json: "",
                                                                       grid_mission_rewards_attributes: {"0" => {id: reward.id, _destroy: "1"}}}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "is required for published missions", 'action="/root/grid_missions/first-contact"')
    expect(response.body).to match(/<div class="rc-row" hidden="hidden">\s*<input[^>]*name="grid_mission\[grid_mission_rewards_attributes\]\[0\]\[position\]"/)
    expect(response.body).to match(/<div class="rc-row">\s*<input[^>]*value="2"[^>]*name="grid_mission\[grid_mission_rewards_attributes\]\[1\]\[position\]"/)
    expect(response.body).to match(/<div class="rc-row">\s*<input[^>]*value="1"[^>]*name="grid_mission\[grid_mission_objectives_attributes\]\[0\]\[position\]"/)
    expect(mission.reload.giver_mob_id).to eq(giver.id)
    expect(mission.grid_mission_rewards).to eq([reward])
  end

  it "refuses a DIALOGUE PATH that is not a JSON array instead of dropping the gate" do
    mission = create(:grid_mission, slug: "first-contact", giver_mob: giver, dialogue_path: ["work"])
    log_in!(admin)

    patch "/root/grid_missions/first-contact", params: {grid_mission: {name: "Renamed", dialogue_path_json: '["work"'}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "Dialogue path is not valid JSON", ERB::Util.html_escape('["work"'))
    expect(mission.reload).to have_attributes(name: mission.name, dialogue_path: ["work"])

    patch "/root/grid_missions/first-contact", params: {grid_mission: {dialogue_path_json: '{"topic": "work"}'}}
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Dialogue path must be a JSON array of topic keys")
  end

  it "creates a mission with its first objective and reward and opens its record" do
    log_in!(admin)

    post "/root/grid_missions", params: {grid_mission: {
      slug: "fresh", name: "Fresh", giver_mob_id: giver.id, min_clearance: "0", position: "1", published: "1", dialogue_path_json: "",
      grid_mission_objectives_attributes: {"0" => {position: "1", objective_type: "visit_room", label: "Go", target_slug: "docks", target_count: "1"}},
      grid_mission_rewards_attributes: {"0" => {position: "1", reward_type: "cred", amount: "25", target_slug: "", quantity: "1"}}
    }}

    mission = GridMission.find_by!(slug: "fresh")
    expect(response).to redirect_to("/root/grid_missions/fresh/edit")
    expect(mission.grid_mission_objectives.pluck(:label)).to eq(["Go"])
    expect(mission.grid_mission_rewards.pluck(:reward_type, :amount)).to eq([["cred", 25]])
  end

  it "re-renders a rejected create with the filled rows and one blank row of each" do
    log_in!(admin)

    post "/root/grid_missions", params: {grid_mission: {
      slug: "fresh", name: "", giver_mob_id: giver.id, published: "1", dialogue_path_json: "",
      grid_mission_objectives_attributes: {"0" => {position: "1", objective_type: "visit_room", label: "Go", target_slug: "docks", target_count: "1"}},
      grid_mission_rewards_attributes: {"0" => {position: "1", reward_type: "", amount: "", target_slug: "", quantity: "1"}}
    }}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include('value="Go"')
    expect(response.body).to match(/<input[^>]*value="2"[^>]*name="grid_mission\[grid_mission_objectives_attributes\]\[1\]\[position\]"/)
    expect(response.body).to match(/<input[^>]*value="1"[^>]*name="grid_mission\[grid_mission_rewards_attributes\]\[0\]\[position\]"/)
    expect(GridMission.exists?(slug: "fresh")).to be(false)
  end

  it "refuses to delete a mission a hackr has active; deletes it otherwise" do
    mission = create(:grid_mission, slug: "first-contact", giver_mob: giver)
    hackr_mission = create(:grid_hackr_mission, grid_mission: mission, grid_hackr: operative)
    log_in!(admin)

    expect { delete "/root/grid_missions/first-contact" }.not_to change(GridMission, :count)
    expect(response).to redirect_to("/root/grid_missions/first-contact/edit")
    follow_redirect!
    expect(response.body).to include("[ERR]", "currently have this mission active")

    hackr_mission.update!(status: "completed", completed_at: Time.current)
    expect { delete "/root/grid_missions/first-contact" }.to change(GridMission, :count).by(-1)
    expect(response).to redirect_to("/root/grid_missions")
  end
end
