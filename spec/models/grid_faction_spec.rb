# == Schema Information
#
# Table name: grid_factions
# Database name: primary
#
#  id           :integer          not null, primary key
#  color_scheme :string
#  description  :text
#  kind         :string           default("collective"), not null
#  name         :string
#  position     :integer          default(0), not null
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer
#  parent_id    :integer
#
# Indexes
#
#  index_grid_factions_on_kind       (kind)
#  index_grid_factions_on_parent_id  (parent_id)
#  index_grid_factions_on_slug       (slug) UNIQUE
#
# Foreign Keys
#
#  parent_id  (parent_id => grid_factions.id)
#
require "rails_helper"

RSpec.describe GridFaction, type: :model do
  describe "validations" do
    it "requires a name" do
      expect(build(:grid_faction, name: nil)).not_to be_valid
    end

    it "requires a unique slug" do
      create(:grid_faction, slug: "same")
      expect(build(:grid_faction, slug: "same")).not_to be_valid
    end

    it "restricts kind to KINDS" do
      expect(build(:grid_faction, kind: "bogus")).not_to be_valid
      GridFaction::KINDS.each do |k|
        expect(build(:grid_faction, kind: k)).to be_valid
      end
    end
  end

  describe "hierarchy" do
    it "exposes children via parent_id" do
      parent = create(:grid_faction)
      child1 = create(:grid_faction, parent: parent)
      child2 = create(:grid_faction, parent: parent)
      expect(parent.children).to match_array([child1, child2])
    end

    it "nullifies children on destroy (does not cascade)" do
      parent = create(:grid_faction)
      child = create(:grid_faction, parent: parent)
      parent.destroy!
      expect(child.reload.parent_id).to be_nil
    end

    it "rejects setting parent to self" do
      f = create(:grid_faction)
      f.parent_id = f.id
      expect(f).not_to be_valid
      expect(f.errors[:parent_id].join).to match(/self/)
    end

    it "rejects a 2-node parent cycle (A.parent=B, B.parent=A)" do
      a = create(:grid_faction)
      b = create(:grid_faction, parent: a)
      a.parent_id = b.id
      expect(a).not_to be_valid
      expect(a.errors[:parent_id].join).to match(/cycle/)
    end

    it "rejects a 3-node parent cycle" do
      a = create(:grid_faction)
      b = create(:grid_faction, parent: a)
      c = create(:grid_faction, parent: b)
      a.parent_id = c.id
      expect(a).not_to be_valid
    end
  end

  describe "rep links" do
    let(:a) { create(:grid_faction) }
    let(:b) { create(:grid_faction) }

    it "#aggregate? is true when incoming links exist" do
      create(:grid_faction_rep_link, source_faction: a, target_faction: b)
      expect(b.aggregate?).to be(true)
      expect(a.aggregate?).to be(false)
    end

    it "destroys incoming + outgoing links on destroy" do
      create(:grid_faction_rep_link, source_faction: a, target_faction: b)
      expect { a.destroy! }.to change { GridFactionRepLink.count }.by(-1)
    end
  end

  describe "polymorphic rep cascade" do
    let(:faction) { create(:grid_faction) }
    let(:hackr) { create(:grid_hackr) }

    it "destroys associated grid_hackr_reputations on destroy" do
      Grid::ReputationService.new(hackr).adjust!(faction, 50, reason: "test")
      expect { faction.destroy! }.to change { GridHackrReputation.count }.by(-1)
    end

    it "destroys associated grid_reputation_events on destroy" do
      Grid::ReputationService.new(hackr).adjust!(faction, 50, reason: "test")
      Grid::ReputationService.new(hackr).adjust!(faction, 20, reason: "test:two")
      expect { faction.destroy! }.to change { GridReputationEvent.count }.by(-2)
    end
  end
end
