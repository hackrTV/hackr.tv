require "rails_helper"

RSpec.describe GridFactionRepLink, type: :model do
  let(:a) { create(:grid_faction) }
  let(:b) { create(:grid_faction) }

  it "rejects a self-link" do
    link = build(:grid_faction_rep_link, source_faction: a, target_faction: a)
    expect(link).not_to be_valid
  end

  it "enforces uniqueness on (source, target)" do
    create(:grid_faction_rep_link, source_faction: a, target_faction: b, weight: 1.0)
    dup = build(:grid_faction_rep_link, source_faction: a, target_faction: b, weight: 2.0)
    expect(dup).not_to be_valid
  end

  it "accepts negative weights" do
    link = build(:grid_faction_rep_link, source_faction: a, target_faction: b, weight: -0.2)
    expect(link).to be_valid
  end

  it "exposes the source and target factions via GridFaction associations" do
    create(:grid_faction_rep_link, source_faction: a, target_faction: b, weight: 1.2)
    expect(a.rep_targets).to include(b)
    expect(b.rep_sources).to include(a)
  end

  describe "cycle prevention" do
    let(:c) { create(:grid_faction) }

    it "rejects a 2-node back-edge (A→B exists, B→A attempted)" do
      create(:grid_faction_rep_link, source_faction: a, target_faction: b, weight: 1.0)
      backedge = build(:grid_faction_rep_link, source_faction: b, target_faction: a, weight: 0.5)
      expect(backedge).not_to be_valid
      expect(backedge.errors[:base].join).to match(/cycle/)
    end

    it "rejects a 3-node cycle (A→B, B→C, C→A)" do
      create(:grid_faction_rep_link, source_faction: a, target_faction: b, weight: 1.0)
      create(:grid_faction_rep_link, source_faction: b, target_faction: c, weight: 1.0)
      backedge = build(:grid_faction_rep_link, source_faction: c, target_faction: a, weight: 1.0)
      expect(backedge).not_to be_valid
    end

    it "accepts a DAG with multiple incoming edges" do
      create(:grid_faction_rep_link, source_faction: a, target_faction: c, weight: 1.0)
      second = build(:grid_faction_rep_link, source_faction: b, target_faction: c, weight: 1.0)
      expect(second).to be_valid
    end

    it "accepts updating an existing edge's weight without re-triggering cycle check against itself" do
      link = create(:grid_faction_rep_link, source_faction: a, target_faction: b, weight: 1.0)
      link.weight = 2.5
      expect(link).to be_valid
    end
  end
end
