require "rails_helper"

RSpec.describe Grid::MissionService do
  let(:hackr) { create(:grid_hackr) }
  let(:giver_room) { create(:grid_room) }
  let(:other_room) { create(:grid_room) }
  let(:giver) { create(:grid_mob, :quest_giver, grid_room: giver_room) }
  let(:mission) { create(:grid_mission, giver_mob: giver) }
  let(:service) { described_class.new(hackr) }

  before do
    create(:grid_mission_objective, grid_mission: mission, objective_type: "visit_room", target_slug: "x", label: "Go x")
  end

  describe "#accept!" do
    it "creates a GridHackrMission + objective rows in the giver's room" do
      expect {
        service.accept!(mission.slug, room: giver_room)
      }.to change(GridHackrMission, :count).by(1)
        .and change(GridHackrMissionObjective, :count).by(mission.grid_mission_objectives.count)
    end

    it "raises NotAtGiver when hackr is not in the giver's room" do
      expect {
        service.accept!(mission.slug, room: other_room)
      }.to raise_error(Grid::MissionService::NotAtGiver)
    end

    it "raises MissionMissing when slug doesn't exist" do
      expect {
        service.accept!("bogus-slug", room: giver_room)
      }.to raise_error(Grid::MissionService::MissionMissing)
    end

    it "raises ClearanceTooLow when hackr clearance is below requirement" do
      mission.update!(min_clearance: 5)
      expect {
        service.accept!(mission.slug, room: giver_room)
      }.to raise_error(Grid::MissionService::ClearanceTooLow)
    end

    it "raises AlreadyActive when already working on the mission" do
      service.accept!(mission.slug, room: giver_room)
      expect {
        service.accept!(mission.slug, room: giver_room)
      }.to raise_error(Grid::MissionService::AlreadyActive)
    end

    it "raises PrereqUnmet when prereq mission hasn't been completed" do
      prereq = create(:grid_mission)
      mission.update!(prereq_mission: prereq)
      expect {
        service.accept!(mission.slug, room: giver_room)
      }.to raise_error(Grid::MissionService::PrereqUnmet)
    end

    it "allows accept when prereq has been completed" do
      prereq = create(:grid_mission)
      mission.update!(prereq_mission: prereq)
      create(:grid_hackr_mission, :completed, grid_hackr: hackr, grid_mission: prereq)

      expect {
        service.accept!(mission.slug, room: giver_room)
      }.not_to raise_error
    end

    it "raises MissionMissing for an unpublished mission (slug guess leak)" do
      mission.update!(published: false)
      expect {
        service.accept!(mission.slug, room: giver_room)
      }.to raise_error(Grid::MissionService::MissionMissing)
    end

    it "raises AlreadyCompletedNonRepeatable for a non-repeatable mission" do
      create(:grid_hackr_mission, :completed, grid_hackr: hackr, grid_mission: mission)
      expect {
        service.accept!(mission.slug, room: giver_room)
      }.to raise_error(Grid::MissionService::AlreadyCompletedNonRepeatable)
    end

    it "allows repeatable missions to be re-accepted after completion" do
      mission.update!(repeatable: true)
      create(:grid_hackr_mission, :completed, grid_hackr: hackr, grid_mission: mission)

      expect { service.accept!(mission.slug, room: giver_room) }.not_to raise_error
    end

    it "does NOT advance sibling missions' threshold objectives on accept" do
      # Sibling mission B is already accepted with a reach_clearance
      # objective. The hackr is at CL0, so B's objective is NOT yet
      # satisfied. Accepting mission A (with its own reach_clearance
      # objective) should scope its threshold-seeding strictly to A —
      # B must stay untouched.
      mission_b = create(:grid_mission, slug: "sibling-threshold")
      obj_b = create(:grid_mission_objective, :reach_clearance,
        grid_mission: mission_b, target_count: 1, label: "Hit CL1")
      hackr_mission_b = create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission_b)
      hackr_obj_b = create(:grid_hackr_mission_objective,
        grid_hackr_mission: hackr_mission_b, grid_mission_objective: obj_b, progress: 0)

      # Mission A also has a reach_clearance objective (at a level above
      # the hackr's current CL) so the seed path runs but doesn't fire
      # globally.
      create(:grid_mission_objective, :reach_clearance, grid_mission: mission, target_count: 5)

      service.accept!(mission.slug, room: giver_room)

      hackr_obj_b.reload
      expect(hackr_obj_b.progress).to eq(0)
      expect(hackr_obj_b.completed_at).to be_nil
    end

    it "seeds this mission's threshold objectives with current state" do
      hackr.grant_xp!(GridHackr::Stats.xp_for_clearance(3))  # push to CL3
      create(:grid_mission_objective, :reach_clearance,
        grid_mission: mission, target_count: 2, label: "Hit CL2")

      hackr_mission = service.accept!(mission.slug, room: giver_room)

      obj_row = hackr_mission.grid_hackr_mission_objectives
        .joins(:grid_mission_objective).where(grid_mission_objectives: {objective_type: "reach_clearance"}).first
      expect(obj_row.completed_at).not_to be_nil
    end
  end

  describe "#accept! rep gate" do
    it "raises RepTooLow when hackr rep is below min_rep_value" do
      faction = create(:grid_faction, slug: "acceptgate-faction", name: "Gate Faction")
      mission.update!(min_rep_faction: faction, min_rep_value: 100)
      expect {
        service.accept!(mission.slug, room: giver_room)
      }.to raise_error(Grid::MissionService::RepTooLow)
    end

    it "allows accept when rep meets min_rep_value" do
      faction = create(:grid_faction, slug: "acceptgate-faction-ok", name: "OK Faction")
      mission.update!(min_rep_faction: faction, min_rep_value: 10)
      Grid::ReputationService.new(hackr).adjust!(faction, 20, reason: "test:seed")

      expect {
        service.accept!(mission.slug, room: giver_room)
      }.not_to raise_error
    end
  end

  describe "#turn_in!" do
    # `turn_in!` is the reward commit path. These specs cover each
    # failure mode at the service boundary and assert the happy path
    # delegates to MissionRewardGranter.
    let!(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }
    let!(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }

    before do
      # Fund the gameplay pool so any CRED reward can mint.
      genesis_source = create(:grid_cache)
      GridTransaction.create!(
        from_cache: genesis_source, to_cache: gameplay_pool, amount: 1_000_000,
        tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
      )
    end

    def accept_and_complete_all_objectives
      hm = service.accept!(mission.slug, room: giver_room)
      # Mark every progress row complete so the readiness check passes.
      hm.grid_hackr_mission_objectives.update_all(
        progress: 1, completed_at: Time.current
      )
      hm.reload
      hm
    end

    it "raises NotActive when no active instance exists for the slug" do
      expect {
        service.turn_in!(mission.slug, room: giver_room)
      }.to raise_error(Grid::MissionService::NotActive)
    end

    it "raises ObjectivesIncomplete when objectives aren't all done" do
      service.accept!(mission.slug, room: giver_room)
      expect {
        service.turn_in!(mission.slug, room: giver_room)
      }.to raise_error(Grid::MissionService::ObjectivesIncomplete)
    end

    it "raises NotAtTurnIn when hackr is not in the giver's room" do
      accept_and_complete_all_objectives
      expect {
        service.turn_in!(mission.slug, room: other_room)
      }.to raise_error(Grid::MissionService::NotAtTurnIn, /Return to/)
    end

    it "completes the mission and grants rewards (happy path)" do
      create(:grid_mission_reward, grid_mission: mission, reward_type: "xp", amount: 75)
      create(:grid_mission_reward, grid_mission: mission, reward_type: "cred", amount: 25)
      accept_and_complete_all_objectives

      outcome = nil
      expect {
        outcome = service.turn_in!(mission.slug, room: giver_room)
      }.to change { hackr.reload.stat("xp") }.by(75)
        .and change { cache.reload.balance }.by(25)

      expect(outcome[:notification_html]).to include("MISSION COMPLETE")
      expect(outcome[:xp_granted]).to eq(75)
      expect(outcome[:cred_granted]).to eq(25)

      hm = hackr.grid_hackr_missions.find_by(grid_mission: mission)
      expect(hm.status).to eq("completed")
      expect(hm.turn_in_count).to eq(1)
    end

    it "increments turn_in_count on each successful turn-in for repeatables" do
      mission.update!(repeatable: true)
      create(:grid_mission_reward, grid_mission: mission, reward_type: "xp", amount: 10)

      # First run.
      accept_and_complete_all_objectives
      service.turn_in!(mission.slug, room: giver_room)

      # Second run — re-accept and complete again.
      hm2 = service.accept!(mission.slug, room: giver_room)
      hm2.grid_hackr_mission_objectives.update_all(progress: 1, completed_at: Time.current)
      service.turn_in!(mission.slug, room: giver_room)

      # Two completed rows, each with turn_in_count == 1.
      completed = hackr.grid_hackr_missions.completed.where(grid_mission: mission)
      expect(completed.count).to eq(2)
      expect(completed.sum(:turn_in_count)).to eq(2)
    end
  end

  describe "#abandon!" do
    it "destroys the active hackr_mission row (free re-accept)" do
      hm = service.accept!(mission.slug, room: giver_room)

      expect { service.abandon!(mission.slug) }
        .to change(GridHackrMission, :count).by(-1)
      expect(GridHackrMission.find_by(id: hm.id)).to be_nil
    end

    it "raises NotActive when not currently active" do
      expect {
        service.abandon!(mission.slug)
      }.to raise_error(Grid::MissionService::NotActive)
    end
  end

  describe "#active_hackr_missions eager loading" do
    # Regression: the missions API used to issue 2 extra queries per
    # active mission (one for mission objectives, one for the progress
    # rows) via `all_objectives_completed?`. Preloading both
    # associations means loading 10 active missions + readiness checks
    # runs in a constant number of queries — not O(N).
    it "evaluates all_objectives_completed? without per-mission DB queries" do
      # Seed 3 active missions with 2 objectives each.
      3.times do |i|
        m = create(:grid_mission, slug: "eager-m-#{i}")
        create(:grid_mission_objective, grid_mission: m, objective_type: "visit_room", target_slug: "r-#{i}")
        create(:grid_mission_objective, grid_mission: m, objective_type: "talk_npc", target_slug: "npc-#{i}")
        hm = create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: m)
        m.grid_mission_objectives.each do |obj|
          create(:grid_hackr_mission_objective, grid_hackr_mission: hm, grid_mission_objective: obj)
        end
      end

      preloaded = service.active_hackr_missions.to_a

      # With preloading in place, walking every mission + calling
      # all_objectives_completed? should issue ZERO additional queries
      # beyond the association load.
      queries = []
      callback = ->(_n, _s, _f, _id, p) { queries << p[:sql] unless p[:sql].include?("sqlite_master") }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        preloaded.each { |hm| hm.all_objectives_completed? }
      end
      expect(queries).to be_empty
    end
  end

  describe "#available_missions query count" do
    # Regression: `already_active?` used to fire one EXISTS per candidate
    # mission. Mirror the memoized `completed_mission_ids` pattern so the
    # cost scales with hackr state (2 plucks), not candidate count.
    it "does not scale queries with candidate count" do
      5.times do |i|
        create(:grid_mission, slug: "avail-m-#{i}", giver_mob: giver)
      end

      queries = []
      callback = ->(_n, _s, _f, _id, p) do
        queries << p[:sql] unless p[:sql].include?("sqlite_master") || p[:sql].start_with?("SAVEPOINT", "RELEASE")
      end
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        Grid::MissionService.new(hackr).available_missions(giver_room).to_a
      end

      # EXISTS-per-candidate was the old bug. Assert specifically that
      # there is at most ONE `grid_hackr_missions` read (the memoized
      # active_mission_ids pluck) regardless of candidate count.
      hackr_mission_reads = queries.count { |q| q.include?("grid_hackr_missions") && q.include?("status") }
      expect(hackr_mission_reads).to be <= 2 # one for active_mission_ids, one for completed_mission_ids
    end
  end

  describe "#available_missions" do
    it "returns missions from the current room's NPCs with gates met" do
      mission # ensure created
      result = service.available_missions(giver_room)
      expect(result).to include(mission)
    end

    it "filters out missions with unmet clearance gate" do
      mission.update!(min_clearance: 10)
      expect(service.available_missions(giver_room)).not_to include(mission)
    end

    it "filters out already-active missions" do
      service.accept!(mission.slug, room: giver_room)
      expect(service.available_missions(giver_room)).not_to include(mission)
    end
  end
end
