# == Schema Information
#
# Table name: grid_hackr_reputations
# Database name: primary
#
#  id            :integer          not null, primary key
#  subject_type  :string           not null
#  value         :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  subject_id    :bigint           not null
#
# Indexes
#
#  index_grid_hackr_reputations_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_reputations_on_subject             (subject_type,subject_id)
#  index_hackr_reputations_unique                 (grid_hackr_id,subject_type,subject_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
require "rails_helper"

RSpec.describe GridHackrReputation, type: :model do
  let(:hackr) { create(:grid_hackr) }
  let(:faction) { create(:grid_faction) }

  it "enforces uniqueness on (hackr, subject)" do
    create(:grid_hackr_reputation, grid_hackr: hackr, subject: faction, value: 10)
    dupe = build(:grid_hackr_reputation, grid_hackr: hackr, subject: faction, value: 20)
    expect(dupe).not_to be_valid
  end

  it "rejects values below MIN_VALUE" do
    rep = build(:grid_hackr_reputation, grid_hackr: hackr, subject: faction, value: -1001)
    expect(rep).not_to be_valid
  end

  it "rejects values above MAX_VALUE" do
    rep = build(:grid_hackr_reputation, grid_hackr: hackr, subject: faction, value: 1001)
    expect(rep).not_to be_valid
  end

  it "accepts zero" do
    rep = build(:grid_hackr_reputation, grid_hackr: hackr, subject: faction, value: 0)
    expect(rep).to be_valid
  end

  describe "scopes" do
    it ".nonzero excludes zero rows" do
      create(:grid_hackr_reputation, grid_hackr: hackr, subject: faction, value: 0)
      create(:grid_hackr_reputation, grid_hackr: hackr, subject: create(:grid_faction), value: 10)
      expect(described_class.nonzero.count).to eq(1)
    end
  end
end

FactoryBot.define do
  factory :grid_hackr_reputation do
    association :grid_hackr
    association :subject, factory: :grid_faction
    value { 0 }
  end
end
