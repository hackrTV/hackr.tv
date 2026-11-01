require "rails_helper"

# /root/grid_hackr_missions — missions taken by hackrs and one
# assignment's readout as console screens (console-ui-for-all-admin
# Phase 4, 2026-11-01).
RSpec.describe "Admin grid hackr missions", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:runner) { create(:grid_hackr, hackr_alias: "Runner") }
  let!(:mission) { create(:grid_mission, name: "Dock Sweep", slug: "dock-sweep") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_hackr_missions"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the assignments as numbered rows with the STATUS row, the hackr filter, destinations and the prompt" do
    active = create(:grid_hackr_mission, grid_hackr: runner, grid_mission: mission, accepted_at: Time.zone.parse("2126-04-05 06:07"))
    create(:grid_hackr_mission, :completed, grid_hackr: create(:grid_hackr, hackr_alias: "Walker"))
    log_in!(admin)

    get "/root/grid_hackr_missions"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 assignments", "[01]", "[02]", 'data-command="02"', "Dock Sweep", "dock-sweep", "Runner", "ACTIVE", "COMPLETED", "2126-04-05 06:07")
    expect(body).to include("/root/grid_hackr_missions/#{active.id}", "/root/grid_hackr_missions?status=completed")
    expect(body).to include("[MISSIONS]", "[IMPOUND]", "type an assignment number")
    expect(body).not_to include("[ASSIGNMENTS]")
  end

  it "narrows by status and hackr, keeps the hackr in the STATUS links, and ignores an unknown status" do
    create(:grid_hackr_mission, grid_hackr: runner, grid_mission: mission)
    create(:grid_hackr_mission, :completed, grid_hackr: runner)
    create(:grid_hackr_mission, :completed, grid_hackr: create(:grid_hackr, hackr_alias: "Walker"))
    log_in!(admin)

    get "/root/grid_hackr_missions", params: {status: "completed", hackr_alias: "runner"}
    body = response.body
    expect(body).to include("1 assignment", "filtered", 'value="runner"', "/root/grid_hackr_missions?hackr_alias=runner&amp;status=active")
    expect(body[/<input type="hidden" name="status"[^>]*>/]).to include('value="completed"')
    expect(body).not_to include("Walker")

    get "/root/grid_hackr_missions", params: {status: "bogus"}
    expect(response.body).to include("3 assignments")
    expect(response.body).not_to include('name="status"')

    get "/root/grid_hackr_missions", params: {hackr_alias: "ghost"}
    expect(response.body).to include("NO ASSIGNMENTS MATCH")
  end

  it "reads one assignment out with its objectives' progress" do
    done = create(:grid_mission_objective, grid_mission: mission, label: "Reach the pier", objective_type: "visit_room", target_slug: "pier-9", target_count: 1)
    open = create(:grid_mission_objective, grid_mission: mission, label: "Talk to the dockhand", objective_type: "talk_npc", target_slug: "dockhand", target_count: 3)
    hm = create(:grid_hackr_mission, grid_hackr: runner, grid_mission: mission, turn_in_count: 2)
    GridHackrMissionObjective.create!(grid_hackr_mission: hm, grid_mission_objective: done, progress: 1, completed_at: Time.current)
    GridHackrMissionObjective.create!(grid_hackr_mission: hm, grid_mission_objective: open, progress: 2)
    log_in!(admin)

    get "/root/grid_hackr_missions/#{hm.id}"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("ASSIGNMENT ##{hm.id}", "Dock Sweep", "Runner", "ACTIVE", "TURN-INS")
    expect(body).to include("/root/grid_missions/dock-sweep/edit", "/root/grid_hackrs/#{runner.id}", "/root/grid_hackr_missions")
    expect(body).to include("// OBJECTIVES · 2 //", "Reach the pier", "VISIT_ROOM", "pier-9", "1 / 1", "DONE", "Talk to the dockhand", "2 / 3")
  end
end
