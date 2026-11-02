require "rails_helper"

# /root/grid_mission_wizard/new — the mission wizard as a console screen
# (console-ui-for-all-admin Phase 4, 2026-11-01): seven steps on one
# screen (the script switches them), the fields and ids it drives, the
# create that opens the mission's record, and a rejected create.
RSpec.describe "Admin grid mission wizard", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_mission_wizard/new"

    expect(response).not_to have_http_status(:ok)
  end

  it "renders every step with its fields, the ids its script drives, destinations and the prompt" do
    create(:grid_mission_arc, name: "The Fracture")
    log_in!(admin)

    get "/root/grid_mission_wizard/new"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include('data-rejected="false"')
    (1..7).each { |n| expect(body).to include(%(id="step-#{n}"), %(data-step="#{n}"), "// STEP #{n}/7 ") }
    expect(body).to include('id="wizard-form"', 'data-rejected="false"', 'id="draft-banner"', 'id="review-content"')
    %w[arc_mode mob_mode room_mode arc_id mob_id mob_room_id].each { |name| expect(body).to include(%(name="#{name}")) }
    %w[name slug description position published].each { |f| expect(body).to include(%(name="new_arc[#{f}]")) }
    %w[name description].each { |f| expect(body).to include(%(name="new_mob[#{f}]")) }
    %w[name slug grid_zone_id room_type min_clearance].each { |f| expect(body).to include(%(name="new_room[#{f}]")) }
    %w[slug name description min_clearance position repeatable published prereq_mission_id min_rep_faction_id min_rep_value dialogue_path_json].each do |f|
      expect(body).to include(%(name="mission[#{f}]"))
    end
    %w[arc-select mob-select room-select zone-select prereq-select].each do |key|
      %w[input hidden dropdown status].each { |part| expect(body).to include(%(id="#{key}-#{part}")) }
    end
    %w[arc-select-section arc-create-section mob-select-section mob-create-section room-select-section room-create-section
      arc-name arc-slug arc-description arc-position mob-name mob-description room-name room-slug room-type room-min-cl
      mission-slug mission-name mission-description mission-min-cl mission-position mission-repeatable mission-published
      mission-rep-faction mission-rep-value mission-dialogue-path objectives-tbody rewards-tbody add-objective-btn add-reward-btn
      draft-restore draft-discard btn-back btn-next btn-submit].each { |id| expect(body).to include(%(id="#{id}")) }
    expect(body).to include("[MISSIONS]", "[ARCS]")
    expect(body).not_to include("[WIZARD]")
    script = body[/var STORAGE_KEY.*?<\/script>/m]
    expect(script).to include("The Fracture", "mission_wizard_submitted")
    expect(script).not_to include("tui-", "cssText", "style.display", "onclick", "<tr", "<td")
  end

  it "creates a new arc, a new room, a new giver in it and the mission, then opens the mission's record" do
    zone = create(:grid_zone)
    log_in!(admin)

    post "/root/grid_mission_wizard", params: {
      arc_mode: "create", new_arc: {name: "Ghost Signals", slug: "ghost-signals", description: "A", position: "3", published: "1"},
      mob_mode: "create", new_mob: {name: "WRAITH", description: "M"},
      room_mode: "create", new_room: {name: "Dead Drop", slug: "dead-drop", grid_zone_id: zone.id, room_type: "hub", min_clearance: "2"},
      mission: {
        slug: "first-signal", name: "First Signal", description: "D", min_clearance: "1", position: "4", repeatable: "1", published: "1",
        prereq_mission_id: "", min_rep_faction_id: "", min_rep_value: "0", dialogue_path_json: '["work"]',
        grid_mission_objectives_attributes: {"0" => {position: "1", objective_type: "visit_room", label: "Find it", target_slug: "dead-drop", target_count: "1"}},
        grid_mission_rewards_attributes: {"0" => {position: "1", reward_type: "xp", amount: "30", target_slug: "", quantity: "1"}}
      }
    }

    mission = GridMission.find_by!(slug: "first-signal")
    expect(response).to redirect_to("/root/grid_missions/first-signal/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Mission 'First Signal' created via wizard."))
    expect(mission).to have_attributes(name: "First Signal", min_clearance: 1, position: 4, repeatable: true, dialogue_path: ["work"])
    expect(mission.grid_mission_arc).to have_attributes(slug: "ghost-signals", position: 3)
    expect(mission.giver_mob).to have_attributes(name: "WRAITH", mob_type: "quest_giver")
    expect(mission.giver_mob.grid_room).to have_attributes(slug: "dead-drop", grid_zone_id: zone.id, room_type: "hub", min_clearance: 2)
    expect(mission.grid_mission_objectives.pluck(:label)).to eq(["Find it"])
    expect(mission.grid_mission_rewards.pluck(:amount)).to eq([30])
  end

  it "re-renders a rejected create with a 422, the [ERR] reply and data-rejected for the script, creating nothing" do
    giver = create(:grid_mob, :quest_giver)
    log_in!(admin)

    expect {
      post "/root/grid_mission_wizard", params: {
        arc_mode: "create", new_arc: {name: "Ghost Signals", slug: "ghost-signals", published: "1"},
        mob_mode: "select", mob_id: giver.id,
        mission: {slug: "", name: "", published: "1"}
      }
    }.not_to change(GridMissionArc, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to be_console_clean
    expect(response.body).to include("[ERR]", "can&#39;t be blank", 'data-rejected="true"')
  end

  it "refuses a DIALOGUE PATH that is not a JSON array instead of dropping the gate, creating nothing" do
    giver = create(:grid_mob, :quest_giver)
    log_in!(admin)

    ['["work"', '{"topic": "work"}'].each do |raw|
      expect {
        post "/root/grid_mission_wizard", params: {
          arc_mode: "create", new_arc: {name: "Ghost Signals", slug: "ghost-signals", published: "1"},
          mob_mode: "select", mob_id: giver.id,
          mission: {slug: "first-signal", name: "First Signal", published: "1", dialogue_path_json: raw}
        }
      }.not_to change { [GridMission.count, GridMissionArc.count] }

      expect(response).to have_http_status(:unprocessable_entity)
    end
    expect(response.body).to include("[ERR]", "Dialogue path must be a JSON array of topic keys")
  end
end
