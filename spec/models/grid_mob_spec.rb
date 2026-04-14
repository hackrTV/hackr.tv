# == Schema Information
#
# Table name: grid_mobs
# Database name: primary
#
#  id              :integer          not null, primary key
#  description     :text
#  dialogue_tree   :json
#  mob_type        :string
#  name            :string
#  vendor_config   :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_faction_id :integer
#  grid_room_id    :integer
#
require "rails_helper"

RSpec.describe GridMob, type: :model do
  describe "faction_not_aggregate" do
    let(:leaf) { create(:grid_faction, slug: "leaf") }
    let(:aggregate) { create(:grid_faction, slug: "agg") }

    before do
      create(:grid_faction_rep_link, source_faction: leaf, target_faction: aggregate, weight: 1.0)
    end

    it "accepts a leaf faction" do
      mob = build(:grid_mob, grid_faction: leaf)
      expect(mob).to be_valid
    end

    it "accepts a nil faction" do
      mob = build(:grid_mob, grid_faction: nil)
      expect(mob).to be_valid
    end

    it "rejects an aggregate faction" do
      mob = build(:grid_mob, grid_faction: aggregate)
      expect(mob).not_to be_valid
      expect(mob.errors[:grid_faction].join).to match(/aggregate/)
    end
  end
end
