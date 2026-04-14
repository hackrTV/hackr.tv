require "rails_helper"

RSpec.describe GridReputationEvent, type: :model do
  let(:hackr) { create(:grid_hackr) }
  let(:faction) { create(:grid_faction) }

  def make(**attrs)
    described_class.create!({
      grid_hackr: hackr,
      subject: faction,
      delta: 5,
      value_after: 5,
      reason: "test"
    }.merge(attrs))
  end

  it "requires delta and value_after" do
    event = described_class.new(grid_hackr: hackr, subject: faction)
    event.valid?
    expect(event.errors[:delta]).not_to be_empty
    expect(event.errors[:value_after]).not_to be_empty
  end

  it "rejects updates to persisted events (append-only)" do
    event = make
    event.note = "changed"
    expect {
      event.save!
    }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "allows destroy so hackr cascade works" do
    make
    expect {
      hackr.destroy!
    }.to change { described_class.count }.by(-1)
  end

  describe "scopes" do
    it ".recent orders newest first" do
      older = make(created_at: 2.days.ago)
      newer = make(created_at: 1.hour.ago)
      expect(described_class.recent.to_a).to eq([newer, older])
    end

    it ".for_subject scopes by subject polymorphic pair" do
      other = create(:grid_faction)
      make(subject: faction)
      make(subject: other)
      expect(described_class.for_subject(faction).count).to eq(1)
    end
  end
end
