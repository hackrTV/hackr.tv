require "rails_helper"

RSpec.describe OverlayTicker, type: :model do
  describe "validations" do
    subject { build(:overlay_ticker) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_inclusion_of(:slug).in_array(OverlayTicker::POSITIONS) }
    it { should validate_presence_of(:content) }
    it { should validate_numericality_of(:speed).is_greater_than(0) }
    it { should validate_inclusion_of(:direction).in_array(OverlayTicker::DIRECTIONS) }
  end

  describe "scopes" do
    let!(:active_ticker) { create(:overlay_ticker, active: true) }
    let!(:inactive_ticker) { create(:overlay_ticker, :bottom, :inactive) }

    it ".active returns only active tickers" do
      expect(OverlayTicker.active).to include(active_ticker)
      expect(OverlayTicker.active).not_to include(inactive_ticker)
    end
  end

  describe ".top" do
    it "returns the top ticker" do
      top = create(:overlay_ticker, slug: "top")
      create(:overlay_ticker, slug: "bottom")

      expect(OverlayTicker.top).to eq(top)
    end

    it "returns nil if no top ticker" do
      expect(OverlayTicker.top).to be_nil
    end
  end

  describe ".bottom" do
    it "returns the bottom ticker" do
      create(:overlay_ticker, slug: "top")
      bottom = create(:overlay_ticker, slug: "bottom")

      expect(OverlayTicker.bottom).to eq(bottom)
    end

    it "returns nil if no bottom ticker" do
      expect(OverlayTicker.bottom).to be_nil
    end
  end

  describe "#broadcast_update!" do
    let(:ticker) { create(:overlay_ticker, slug: "top", content: "Test content", speed: 50, direction: "left", active: true) }

    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "broadcasts to overlay channel" do
      expect(ActionCable.server).to receive(:broadcast).with(
        "overlay_updates",
        {
          type: "ticker_updated",
          data: {
            slug: "top",
            content: "Test content",
            speed: 50,
            direction: "left",
            active: true
          }
        }
      )

      ticker.broadcast_update!
    end
  end
end
