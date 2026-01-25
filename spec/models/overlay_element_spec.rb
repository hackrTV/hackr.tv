# == Schema Information
#
# Table name: overlay_elements
# Database name: primary
#
#  id           :integer          not null, primary key
#  active       :boolean          default(TRUE)
#  element_type :string           not null
#  name         :string           not null
#  settings     :json
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_overlay_elements_on_active        (active)
#  index_overlay_elements_on_element_type  (element_type)
#  index_overlay_elements_on_slug          (slug) UNIQUE
#
require "rails_helper"

RSpec.describe OverlayElement, type: :model do
  describe "associations" do
    it { should have_many(:overlay_scene_elements).dependent(:destroy) }
    it { should have_many(:overlay_scenes).through(:overlay_scene_elements) }
  end

  describe "validations" do
    subject { build(:overlay_element) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_presence_of(:element_type) }
    it { should validate_inclusion_of(:element_type).in_array(OverlayElement::ELEMENT_TYPES) }

    it "requires slug presence (auto-generated from name)" do
      element = build(:overlay_element, name: nil, slug: nil)
      expect(element).not_to be_valid
      expect(element.errors[:slug]).to include("can't be blank")
    end

    it "validates slug format" do
      element = build(:overlay_element, slug: "Invalid Slug!")
      expect(element).not_to be_valid
      expect(element.errors[:slug]).to include("must be lowercase alphanumeric with hyphens")
    end

    it "allows valid slug format" do
      element = build(:overlay_element, slug: "valid-slug-123")
      expect(element).to be_valid
    end
  end

  describe "callbacks" do
    it "generates slug from name when slug is blank" do
      element = build(:overlay_element, name: "My Element Name", slug: nil)
      element.validate
      expect(element.slug).to eq("my-element-name")
    end

    it "does not override existing slug" do
      element = build(:overlay_element, name: "My Element", slug: "custom-slug")
      element.validate
      expect(element.slug).to eq("custom-slug")
    end
  end

  describe "scopes" do
    let!(:active_element) { create(:overlay_element, active: true) }
    let!(:inactive_element) { create(:overlay_element, :inactive) }

    it ".active returns only active elements" do
      expect(OverlayElement.active).to include(active_element)
      expect(OverlayElement.active).not_to include(inactive_element)
    end

    it ".by_type filters by element type" do
      now_playing = create(:overlay_element, element_type: "now_playing")
      alert = create(:overlay_element, :alert)

      expect(OverlayElement.by_type("now_playing")).to include(now_playing)
      expect(OverlayElement.by_type("now_playing")).not_to include(alert)
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      element = build(:overlay_element, slug: "my-element")
      expect(element.to_param).to eq("my-element")
    end
  end

  describe "settings accessors" do
    let(:element) { build(:overlay_element, settings: {"codex_entry_slug" => "xeraen", "max_items" => 10, "ticker_slug" => "top", "lower_third_slug" => "host"}) }

    it "#codex_entry_slug returns setting value" do
      expect(element.codex_entry_slug).to eq("xeraen")
    end

    it "#max_items returns setting value or default" do
      expect(element.max_items).to eq(10)
    end

    it "#max_items returns 5 as default" do
      element = build(:overlay_element, settings: {})
      expect(element.max_items).to eq(5)
    end

    it "#ticker_slug returns setting value" do
      expect(element.ticker_slug).to eq("top")
    end

    it "#lower_third_slug returns setting value" do
      expect(element.lower_third_slug).to eq("host")
    end
  end
end
