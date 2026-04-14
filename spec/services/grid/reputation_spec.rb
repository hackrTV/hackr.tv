require "rails_helper"

RSpec.describe Grid::Reputation do
  describe ".tier_for" do
    it "returns BLACKLISTED at floor" do
      expect(described_class.tier_for(-1000)[:key]).to eq(:blacklisted)
      expect(described_class.tier_for(-700)[:key]).to eq(:blacklisted)
    end

    it "returns ARCHITECT at ceiling" do
      expect(described_class.tier_for(800)[:key]).to eq(:architect)
      expect(described_class.tier_for(1000)[:key]).to eq(:architect)
    end

    it "returns UNKNOWN around zero" do
      expect(described_class.tier_for(0)[:key]).to eq(:unknown)
      expect(described_class.tier_for(-49)[:key]).to eq(:unknown)
      expect(described_class.tier_for(49)[:key]).to eq(:unknown)
    end

    it "returns TRUSTED at 50..199" do
      expect(described_class.tier_for(50)[:key]).to eq(:trusted)
      expect(described_class.tier_for(199)[:key]).to eq(:trusted)
    end

    it "returns OPERATIVE at 200..499" do
      expect(described_class.tier_for(200)[:key]).to eq(:operative)
      expect(described_class.tier_for(499)[:key]).to eq(:operative)
    end

    it "returns SPECIALIST at 500..799" do
      expect(described_class.tier_for(500)[:key]).to eq(:specialist)
      expect(described_class.tier_for(799)[:key]).to eq(:specialist)
    end

    it "returns HOSTILE at -599..-200" do
      expect(described_class.tier_for(-200)[:key]).to eq(:hostile)
      expect(described_class.tier_for(-599)[:key]).to eq(:hostile)
    end

    it "tiers strictly increase by threshold" do
      mins = described_class::TIERS.map { |t| t[:min] }
      expect(mins).to eq(mins.sort)
    end
  end

  describe ".next_tier_for" do
    it "returns the next tier up" do
      expect(described_class.next_tier_for(0)[:key]).to eq(:trusted)
      expect(described_class.next_tier_for(100)[:key]).to eq(:operative)
    end

    it "returns nil at ceiling" do
      expect(described_class.next_tier_for(1000)).to be_nil
    end
  end
end
