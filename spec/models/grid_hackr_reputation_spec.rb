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
