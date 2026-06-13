# == Schema Information
#
# Table name: overlay_tickers
# Database name: primary
#
#  id           :integer          not null, primary key
#  active       :boolean          default(TRUE)
#  content      :text             not null
#  content_type :string           default("static"), not null
#  direction    :string           default("left")
#  feed_source  :string
#  name         :string           not null
#  slug         :string           not null
#  speed        :integer          default(50)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_overlay_tickers_on_active  (active)
#  index_overlay_tickers_on_slug    (slug) UNIQUE
#
require "rails_helper"

RSpec.describe OverlayTicker, type: :model do
  describe "validations" do
    subject { build(:overlay_ticker) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }

    it "requires slug when name is also blank" do
      ticker = build(:overlay_ticker, name: nil, slug: nil)
      expect(ticker).not_to be_valid
      expect(ticker.errors[:slug]).to be_present
    end
    it { should validate_numericality_of(:speed).is_greater_than(0) }
    it { should validate_inclusion_of(:direction).in_array(OverlayTicker::DIRECTIONS) }
    it { should validate_inclusion_of(:content_type).in_array(OverlayTicker::CONTENT_TYPES) }

    it "requires content for static tickers" do
      ticker = build(:overlay_ticker, content_type: "static", content: nil)
      expect(ticker).not_to be_valid
      expect(ticker.errors[:content]).to be_present
    end

    it "auto-fills content for dynamic tickers when blank" do
      ticker = build(:overlay_ticker, :dynamic, content: nil)
      ticker.valid?
      expect(ticker.content).to be_present
    end

    it "requires feed_source for dynamic tickers" do
      ticker = build(:overlay_ticker, content_type: "dynamic", feed_source: nil)
      expect(ticker).not_to be_valid
      expect(ticker.errors[:feed_source]).to be_present
    end

    it "validates feed_source inclusion" do
      ticker = build(:overlay_ticker, :dynamic, feed_source: "invalid")
      expect(ticker).not_to be_valid
    end

    it "allows valid feed sources" do
      OverlayTicker::FEED_SOURCES.each do |source|
        ticker = build(:overlay_ticker, :dynamic, feed_source: source)
        expect(ticker).to be_valid, "Expected feed_source '#{source}' to be valid"
      end
    end
  end

  describe "slug auto-generation" do
    it "generates slug from name when blank" do
      ticker = create(:overlay_ticker, name: "My Cool Ticker", slug: "")
      expect(ticker.slug).to eq("my-cool-ticker")
    end
  end

  describe "scopes" do
    let!(:active_ticker) { create(:overlay_ticker, active: true) }
    let!(:inactive_ticker) { create(:overlay_ticker, :inactive) }

    it ".active returns only active tickers" do
      expect(OverlayTicker.active).to include(active_ticker)
      expect(OverlayTicker.active).not_to include(inactive_ticker)
    end
  end

  describe "#static? and #dynamic?" do
    it "returns true for static content_type" do
      ticker = build(:overlay_ticker, content_type: "static")
      expect(ticker.static?).to be true
      expect(ticker.dynamic?).to be false
    end

    it "returns true for dynamic content_type" do
      ticker = build(:overlay_ticker, :dynamic)
      expect(ticker.static?).to be false
      expect(ticker.dynamic?).to be true
    end
  end

  describe "#broadcast_update!" do
    let(:ticker) { create(:overlay_ticker, slug: "test-ticker", content: "Test content", speed: 50, direction: "left", active: true) }

    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "broadcasts to overlay channel with content_type and feed_source" do
      expect(ActionCable.server).to receive(:broadcast).with(
        "overlay_updates",
        {
          type: "ticker_updated",
          data: {
            slug: "test-ticker",
            content: "Test content",
            content_type: "static",
            feed_source: nil,
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
