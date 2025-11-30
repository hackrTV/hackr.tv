require "rails_helper"

RSpec.describe OverlayLowerThird, type: :model do
  describe "validations" do
    subject { build(:overlay_lower_third) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_presence_of(:primary_text) }

    it "requires slug presence (auto-generated from name)" do
      lower_third = build(:overlay_lower_third, name: nil, slug: nil)
      expect(lower_third).not_to be_valid
      expect(lower_third.errors[:slug]).to include("can't be blank")
    end

    it "validates slug format" do
      lower_third = build(:overlay_lower_third, slug: "Invalid Slug!")
      expect(lower_third).not_to be_valid
      expect(lower_third.errors[:slug]).to include("must be lowercase alphanumeric with hyphens")
    end

    it "allows valid slug format" do
      lower_third = build(:overlay_lower_third, slug: "valid-slug-123")
      expect(lower_third).to be_valid
    end
  end

  describe "callbacks" do
    it "generates slug from name when slug is blank" do
      lower_third = build(:overlay_lower_third, name: "Host Introduction", slug: nil)
      lower_third.validate
      expect(lower_third.slug).to eq("host-introduction")
    end

    it "does not override existing slug" do
      lower_third = build(:overlay_lower_third, name: "My Lower Third", slug: "custom-slug")
      lower_third.validate
      expect(lower_third.slug).to eq("custom-slug")
    end

    it "handles special characters in slug generation" do
      lower_third = build(:overlay_lower_third, name: "Guest @#$ Name!", slug: nil)
      lower_third.validate
      expect(lower_third.slug).to eq("guest-name")
    end
  end

  describe "scopes" do
    let!(:active_lower_third) { create(:overlay_lower_third, active: true) }
    let!(:inactive_lower_third) { create(:overlay_lower_third, :inactive) }

    it ".active returns only active lower thirds" do
      expect(OverlayLowerThird.active).to include(active_lower_third)
      expect(OverlayLowerThird.active).not_to include(inactive_lower_third)
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      lower_third = build(:overlay_lower_third, slug: "host-intro")
      expect(lower_third.to_param).to eq("host-intro")
    end
  end

  describe "#broadcast_update!" do
    let(:lower_third) do
      create(:overlay_lower_third,
        slug: "host",
        primary_text: "John Doe",
        secondary_text: "Host",
        logo_url: "https://example.com/logo.png",
        active: true)
    end

    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "broadcasts to overlay channel" do
      expect(ActionCable.server).to receive(:broadcast).with(
        "overlay_updates",
        {
          type: "lower_third_updated",
          data: {
            slug: "host",
            primary_text: "John Doe",
            secondary_text: "Host",
            logo_url: "https://example.com/logo.png",
            active: true
          }
        }
      )

      lower_third.broadcast_update!
    end
  end
end
