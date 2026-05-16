require "rails_helper"

RSpec.describe Grid::RestPodService do
  let(:zone) { create(:grid_zone) }
  let(:rest_room) { create(:grid_room, :rest_pod, grid_zone: zone) }
  let(:standard_room) { create(:grid_room, :standard, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: rest_room) }
  let(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }
  let(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }
  let(:burn_cache) { create(:grid_cache, :burn) }

  def fund_cache(target_cache, amount)
    source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: source, to_cache: target_cache, amount: amount,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  before do
    cache
    gameplay_pool
    burn_cache
  end

  describe ".rate_for" do
    it "returns discounted rate (2) for CL < 30" do
      hackr.set_stat!("clearance", 0)
      expect(described_class.rate_for(hackr)).to eq(2)

      hackr.set_stat!("clearance", 29)
      expect(described_class.rate_for(hackr)).to eq(2)
    end

    it "returns standard rate (1) for CL >= 30" do
      hackr.set_stat!("clearance", 30)
      expect(described_class.rate_for(hackr)).to eq(1)

      hackr.set_stat!("clearance", 99)
      expect(described_class.rate_for(hackr)).to eq(1)
    end
  end

  describe ".restore!" do
    before { fund_cache(cache, 5000) }

    context "room gate" do
      it "raises NotAtRestPod when not in a rest_pod room" do
        hackr.update!(current_room: standard_room)
        expect {
          described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 10}])
        }.to raise_error(described_class::NotAtRestPod)
      end
    end

    context "validation" do
      it "raises InvalidAllocation for empty allocs" do
        expect {
          described_class.restore!(hackr: hackr, allocs: [])
        }.to raise_error(described_class::InvalidAllocation, /No allocation/)
      end

      it "raises InvalidAllocation for unknown vital" do
        expect {
          described_class.restore!(hackr: hackr, allocs: [{vital: "mana", points: 10}])
        }.to raise_error(described_class::InvalidAllocation, /Unknown vital/)
      end

      it "raises InvalidAllocation for non-positive points" do
        expect {
          described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 0}])
        }.to raise_error(described_class::InvalidAllocation, /Points must be positive/)
      end
    end

    context "full vitals" do
      it "raises NothingToRestore when all vitals are at max" do
        hackr.set_stat!("health", 100)
        hackr.set_stat!("energy", 100)
        hackr.set_stat!("psyche", 100)

        expect {
          described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 50}])
        }.to raise_error(described_class::NothingToRestore)
      end
    end

    context "insufficient balance" do
      it "raises InsufficientBalance pre-check when CRED is clearly short" do
        hackr.set_stat!("health", 0)
        # Fund only 10 CRED, try to restore 100 HP at rate 2 = 50 CRED
        cache # already funded with 5000 above, re-fund low
        # Drain all but 10
        Grid::TransactionService.burn!(from_cache: cache, amount: 4990, memo: "drain")

        expect {
          described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 100}])
        }.to raise_error(described_class::InsufficientBalance)
      end
    end

    context "successful restoration" do
      before do
        hackr.set_stat!("health", 50)
        hackr.set_stat!("energy", 70)
        hackr.set_stat!("psyche", 40)
        hackr.set_stat!("clearance", 10) # discounted rate: 2 pts/CRED
      end

      it "restores vitals and charges CRED" do
        result = described_class.restore!(hackr: hackr, allocs: [
          {vital: "health", points: 30},
          {vital: "energy", points: 20}
        ])

        expect(hackr.stat("health")).to eq(80)
        expect(hackr.stat("energy")).to eq(90)
        expect(hackr.stat("psyche")).to eq(40) # unchanged

        # 50 total points / rate 2 = 25 CRED
        expect(result.total_cred_paid).to eq(25)
      end

      it "returns a Result with display HTML" do
        result = described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 10}])
        expect(result.display).to include("REST POD")
        expect(result.display).to include("HEALTH")
        expect(result.display).to include("+10")
      end

      it "burns 70% and recycles 30% of cost" do
        described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 20}])
        # 20 pts / rate 2 = 10 CRED. Burn = 7, recycle = 3
        expect(burn_cache.balance).to eq(7)
        expect(gameplay_pool.balance).to eq(3)
      end

      it "clamps allocation to actual deficit" do
        hackr.set_stat!("health", 95) # only 5 missing
        result = described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 50}])

        expect(hackr.stat("health")).to eq(100)
        # Clamped to 5 pts / rate 2 = ceil(2.5) = 3 CRED
        expect(result.total_cred_paid).to eq(3)
      end

      it "skips vitals that are already full" do
        hackr.set_stat!("health", 100)
        hackr.set_stat!("energy", 80)

        result = described_class.restore!(hackr: hackr, allocs: [
          {vital: "health", points: 50},
          {vital: "energy", points: 10}
        ])

        expect(hackr.stat("health")).to eq(100) # unchanged
        expect(hackr.stat("energy")).to eq(90)
        # Only 10 energy pts counted, health alloc skipped
        expect(result.total_cred_paid).to eq(5) # 10 / 2
      end
    end

    context "veteran rate (CL >= 30)" do
      before do
        hackr.set_stat!("health", 50)
        hackr.set_stat!("clearance", 30) # standard rate: 1 pt/CRED
      end

      it "charges 1:1 rate" do
        result = described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 30}])
        expect(result.total_cred_paid).to eq(30) # 30 pts / rate 1 = 30 CRED
        expect(hackr.stat("health")).to eq(80)
      end
    end

    context "multi-vital allocation" do
      before do
        hackr.set_stat!("health", 50)
        hackr.set_stat!("energy", 60)
        hackr.set_stat!("psyche", 70)
        hackr.set_stat!("clearance", 0) # rate 2
      end

      it "restores all three vitals in one call" do
        result = described_class.restore!(hackr: hackr, allocs: [
          {vital: "health", points: 50},
          {vital: "energy", points: 40},
          {vital: "psyche", points: 30}
        ])

        expect(hackr.stat("health")).to eq(100)
        expect(hackr.stat("energy")).to eq(100)
        expect(hackr.stat("psyche")).to eq(100)
        # 120 total pts / rate 2 = 60 CRED
        expect(result.total_cred_paid).to eq(60)
      end
    end

    context "cost rounding" do
      before do
        hackr.set_stat!("health", 99) # 1 point deficit
        hackr.set_stat!("clearance", 0) # rate 2
      end

      it "rounds cost up (no free healing)" do
        result = described_class.restore!(hackr: hackr, allocs: [{vital: "health", points: 1}])
        # 1 pt / rate 2 = ceil(0.5) = 1 CRED
        expect(result.total_cred_paid).to eq(1)
      end
    end
  end
end
