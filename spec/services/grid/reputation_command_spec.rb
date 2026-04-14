require "rails_helper"

RSpec.describe "CommandParser reputation integration" do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let!(:hackrcore) { create(:grid_faction, slug: "hackrcore", name: "Hackrcore") }
  let!(:fn) { create(:grid_faction, slug: "fn", name: "Fracture Network") }

  before do
    create(:grid_faction_rep_link, source_faction: hackrcore, target_faction: fn, weight: 1.2)
  end

  def run(input)
    Grid::CommandParser.new(hackr, input).execute
  end

  describe "rep command" do
    it "renders a STANDING REPORT header" do
      result = run("rep")
      expect(result[:output]).to include("STANDING REPORT")
    end

    it "aliases to 'reputation' and 'standing'" do
      expect(run("reputation")[:output]).to include("STANDING REPORT")
      expect(run("standing")[:output]).to include("STANDING REPORT")
    end

    it "renders grandchildren when the hierarchy is >1 level deep" do
      # Build top → mid → leaf → grand chain via parent_id
      top = create(:grid_faction, slug: "top", name: "Top Syndicate")
      mid = create(:grid_faction, slug: "mid", name: "Mid Cadre", parent: top)
      leaf = create(:grid_faction, slug: "leaf", name: "Leaf Cell", parent: mid)
      # Put rep somewhere so rows show without include_zero:false filtering.
      Grid::ReputationService.new(hackr).adjust!(leaf, 10, reason: "test")

      out = run("rep")[:output]
      expect(out).to include("Top Syndicate")
      expect(out).to include("Mid Cadre")
      expect(out).to include("Leaf Cell")
      # Depth-1 child: "└─ " prefix. Depth-2 grandchild: extra 2 spaces before "└─ ".
      expect(out).to match(/└─ Mid Cadre/)
      expect(out).to match(/  └─ Leaf Cell/)
    end
  end

  describe "stat command" do
    it "surfaces a STANDING block when the hackr has activity" do
      Grid::ReputationService.new(hackr).adjust!(hackrcore, 75, reason: "test")
      out = run("stat")[:output]
      expect(out).to include("STANDING:")
      expect(out).to include("Hackrcore")
    end

    it "omits STANDING when there's no rep activity" do
      expect(run("stat")[:output]).not_to include("STANDING:")
    end
  end

  describe "talk command rep hook" do
    let(:mob) do
      create(:grid_mob,
        grid_room: room,
        grid_faction: hackrcore,
        dialogue_tree: {"greeting" => "hi"})
    end

    it "grants faction rep when talking to a faction-affiliated NPC" do
      expect {
        run("talk #{mob.name}")
      }.to change { hackr.grid_reputation_events.count }.by(1)
      expect(Grid::ReputationService.new(hackr).leaf_value(hackrcore)).to eq(1)
    end

    it "grants no rep for an NPC with no faction" do
      unaffiliated = create(:grid_mob, grid_room: room, grid_faction: nil, dialogue_tree: {"greeting" => "hi"})
      expect {
        run("talk #{unaffiliated.name}")
      }.not_to change { hackr.grid_reputation_events.count }
    end

    it "skips rep silently when an NPC is misconfigured on an aggregate faction" do
      # Normal creation is now blocked by GridMob's faction_not_aggregate
      # validator, but a mob can still end up pointing at an aggregate if the
      # rep-link graph is edited AFTER the mob was created (or via bypass).
      # Simulate that: assign to leaf first, then mutate the column directly.
      bad = create(:grid_mob, grid_room: room, grid_faction: hackrcore, dialogue_tree: {"greeting" => "hi"})
      bad.update_column(:grid_faction_id, fn.id)
      expect {
        result = run("talk #{bad.name}")
        expect(result[:output]).to include(bad.name)
      }.not_to change { hackr.grid_reputation_events.count }
    end
  end
end
