require "rails_helper"

RSpec.describe Grid::ReputationService do
  let(:hackr) { create(:grid_hackr) }
  let(:service) { described_class.new(hackr) }

  let(:fn) { create(:grid_faction, slug: "fn", name: "Fracture Network") }
  let(:hackrcore) { create(:grid_faction, slug: "hackrcore", name: "Hackrcore", parent: fn) }
  let(:govcorp) { create(:grid_faction, slug: "govcorp", name: "GovCorp") }
  let(:dante) { create(:grid_faction, slug: "dante", name: "Dante", kind: "individual") }

  before do
    # Graph: Hackrcore→FN +1.2, GovCorp→FN -0.2. Dante is unlinked.
    create(:grid_faction_rep_link, source_faction: hackrcore, target_faction: fn, weight: 1.2)
    create(:grid_faction_rep_link, source_faction: govcorp, target_faction: fn, weight: -0.2)
  end

  describe "#adjust!" do
    it "creates a leaf row for a new subject" do
      expect {
        service.adjust!(hackrcore, 25, reason: "test")
      }.to change { GridHackrReputation.count }.by(1)

      rep = hackr.grid_hackr_reputations.find_by(subject: hackrcore)
      expect(rep.value).to eq(25)
    end

    it "appends an event with value_after snapshot" do
      service.adjust!(hackrcore, 10, reason: "test:a")
      service.adjust!(hackrcore, 15, reason: "test:b")

      events = hackr.grid_reputation_events.order(:created_at).to_a
      expect(events.size).to eq(2)
      expect(events.map(&:delta)).to eq([10, 15])
      expect(events.map(&:value_after)).to eq([10, 25])
      expect(events.map(&:reason)).to eq(["test:a", "test:b"])
    end

    it "clamps the stored value to MIN..MAX and reports applied_delta" do
      service.adjust!(hackrcore, 950)
      result = service.adjust!(hackrcore, 200)

      expect(result[:new_value]).to eq(1000)
      expect(result[:applied_delta]).to eq(50)
      expect(result[:requested_delta]).to eq(200)
    end

    it "clamps downward at -1000" do
      service.adjust!(govcorp, -900)
      result = service.adjust!(govcorp, -500)

      expect(result[:new_value]).to eq(-1000)
      expect(result[:applied_delta]).to eq(-100)
    end

    it "reports rollup transitions when an aggregate crosses a tier" do
      # Hackrcore +50 → FN effective = 60 (tier UNKNOWN → TRUSTED at 50)
      result = service.adjust!(hackrcore, 50)
      rollup = result[:rollups].find { |r| r[:faction].id == fn.id }

      expect(rollup).not_to be_nil
      expect(rollup[:old_value]).to eq(0)
      expect(rollup[:new_value]).to eq(60)
      expect(rollup[:tier_before][:key]).to eq(:unknown)
      expect(rollup[:tier_after][:key]).to eq(:trusted)
    end

    it "reports NO rollup for a subject with no outgoing links" do
      result = service.adjust!(dante, 100)
      expect(result[:rollups]).to be_empty
    end

    it "raises SubjectMissing for an unknown slug" do
      expect {
        service.adjust!("no_such_faction", 10)
      }.to raise_error(Grid::ReputationService::SubjectMissing)
    end

    it "refuses to adjust an aggregate subject" do
      expect {
        service.adjust!(fn, 50, reason: "test")
      }.to raise_error(Grid::ReputationService::AggregateSubjectNotAdjustable, /derived/)
    end

    it "does NOT persist a rep row or event when refusing an aggregate write" do
      reps_before = GridHackrReputation.count
      events_before = GridReputationEvent.count
      begin
        service.adjust!(fn, 50)
      rescue Grid::ReputationService::AggregateSubjectNotAdjustable
      end
      expect(GridHackrReputation.count).to eq(reps_before)
      expect(GridReputationEvent.count).to eq(events_before)
    end

    it "accepts a faction slug as the subject" do
      service.adjust!(:hackrcore, 10)
      expect(service.leaf_value(hackrcore)).to eq(10)
    end

    it "is transactional — no rep row if event fails" do
      allow(GridReputationEvent).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      expect {
        begin
          service.adjust!(hackrcore, 10)
        rescue ActiveRecord::RecordInvalid
        end
      }.not_to change { GridHackrReputation.count }
    end
  end

  describe "#effective_rep" do
    it "returns leaf value for a leaf subject" do
      service.adjust!(hackrcore, 100)
      expect(service.effective_rep(hackrcore)).to eq(100)
    end

    it "sums weighted contributions for an aggregate subject" do
      service.adjust!(hackrcore, 100)   # +120 via 1.2x
      service.adjust!(govcorp, 50)      # -10 via -0.2x
      # Net: 120 - 10 = 110
      expect(service.effective_rep(fn)).to eq(110)
    end

    it "clamps aggregate to MIN..MAX" do
      svc_hc = service
      svc_hc.adjust!(hackrcore, 900) # 900 × 1.2 = 1080 → clamped to 1000
      expect(service.effective_rep(fn)).to eq(1000)
    end

    it "returns 0 when no contributions exist" do
      expect(service.effective_rep(fn)).to eq(0)
    end

    it "handles a negative weighted edge" do
      service.adjust!(govcorp, 100)
      # 100 × -0.2 = -20
      expect(service.effective_rep(fn)).to eq(-20)
    end

    it "propagates through chained aggregates (A → B → C)" do
      # Build a fresh 3-level chain: leaf → mid → top
      leaf = create(:grid_faction, slug: "chain_leaf")
      mid = create(:grid_faction, slug: "chain_mid")
      top = create(:grid_faction, slug: "chain_top")
      create(:grid_faction_rep_link, source_faction: leaf, target_faction: mid, weight: 0.5)
      create(:grid_faction_rep_link, source_faction: mid, target_faction: top, weight: 2.0)

      service.adjust!(leaf, 100)

      expect(service.effective_rep(leaf)).to eq(100)
      expect(service.effective_rep(mid)).to eq(50)   # 100 × 0.5
      expect(service.effective_rep(top)).to eq(100)  # effective(mid) × 2.0 = 50 × 2
    end
  end

  describe "#leaf_value" do
    it "returns 0 for a subject with no stored row" do
      expect(service.leaf_value(hackrcore)).to eq(0)
    end

    it "returns stored leaf after adjust" do
      service.adjust!(hackrcore, 42)
      expect(service.leaf_value(hackrcore)).to eq(42)
    end
  end

  describe "#faction_standings" do
    it "omits zero-rep factions by default" do
      service.adjust!(hackrcore, 10)
      slugs = service.faction_standings.map { |s| s[:faction].slug }
      expect(slugs).to include("hackrcore", "fn")
      expect(slugs).not_to include("dante")
    end

    it "includes all factions when include_zero: true" do
      # Force all four factions into existence (let blocks are lazy)
      [fn, hackrcore, govcorp, dante]
      slugs = service.faction_standings(include_zero: true).map { |s| s[:faction].slug }
      expect(slugs).to match_array(%w[fn hackrcore govcorp dante])
    end

    it "flags aggregates" do
      service.adjust!(hackrcore, 100)
      fn_row = service.faction_standings.find { |s| s[:faction].slug == "fn" }
      expect(fn_row[:aggregate]).to be(true)

      hc_row = service.faction_standings.find { |s| s[:faction].slug == "hackrcore" }
      expect(hc_row[:aggregate]).to be(false)
    end
  end
end
