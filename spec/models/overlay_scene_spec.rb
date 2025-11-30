require "rails_helper"

RSpec.describe OverlayScene, type: :model do
  describe "associations" do
    it { should have_many(:overlay_scene_elements).dependent(:destroy) }
    it { should have_many(:overlay_elements).through(:overlay_scene_elements) }
  end

  describe "validations" do
    subject { build(:overlay_scene) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_presence_of(:scene_type) }
    it { should validate_inclusion_of(:scene_type).in_array(OverlayScene::SCENE_TYPES) }
    it { should validate_numericality_of(:width).is_greater_than(0) }
    it { should validate_numericality_of(:height).is_greater_than(0) }

    it "requires slug presence (auto-generated from name)" do
      scene = build(:overlay_scene, name: nil, slug: nil)
      expect(scene).not_to be_valid
      expect(scene.errors[:slug]).to include("can't be blank")
    end

    it "validates slug format" do
      scene = build(:overlay_scene, slug: "Invalid Slug!")
      expect(scene).not_to be_valid
      expect(scene.errors[:slug]).to include("must be lowercase alphanumeric with hyphens")
    end

    it "allows valid slug format" do
      scene = build(:overlay_scene, slug: "valid-slug-123")
      expect(scene).to be_valid
    end
  end

  describe "callbacks" do
    it "generates slug from name when slug is blank" do
      scene = build(:overlay_scene, name: "My Scene Name", slug: nil)
      scene.validate
      expect(scene.slug).to eq("my-scene-name")
    end

    it "does not override existing slug" do
      scene = build(:overlay_scene, name: "My Scene", slug: "custom-slug")
      scene.validate
      expect(scene.slug).to eq("custom-slug")
    end

    it "handles special characters in slug generation" do
      scene = build(:overlay_scene, name: "Scene @#$ Test!", slug: nil)
      scene.validate
      expect(scene.slug).to eq("scene-test")
    end
  end

  describe "scopes" do
    let!(:active_scene) { create(:overlay_scene, active: true) }
    let!(:inactive_scene) { create(:overlay_scene, :inactive) }
    let!(:fullscreen_scene) { create(:overlay_scene, scene_type: "fullscreen") }
    let!(:composition_scene) { create(:overlay_scene, :composition) }

    it ".active returns only active scenes" do
      expect(OverlayScene.active).to include(active_scene)
      expect(OverlayScene.active).not_to include(inactive_scene)
    end

    it ".fullscreen returns only fullscreen scenes" do
      expect(OverlayScene.fullscreen).to include(fullscreen_scene)
      expect(OverlayScene.fullscreen).not_to include(composition_scene)
    end

    it ".compositions returns only composition scenes" do
      expect(OverlayScene.compositions).to include(composition_scene)
      expect(OverlayScene.compositions).not_to include(fullscreen_scene)
    end

    it ".ordered orders by position then name" do
      create(:overlay_scene, name: "Zebra", position: 1)
      create(:overlay_scene, name: "Alpha", position: 1)
      scene_first = create(:overlay_scene, name: "First", position: 0)

      ordered = OverlayScene.ordered
      expect(ordered.first).to eq(scene_first)
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      scene = build(:overlay_scene, slug: "my-scene")
      expect(scene.to_param).to eq("my-scene")
    end
  end

  describe "#fullscreen?" do
    it "returns true for fullscreen scenes" do
      scene = build(:overlay_scene, scene_type: "fullscreen")
      expect(scene.fullscreen?).to be true
    end

    it "returns false for composition scenes" do
      scene = build(:overlay_scene, scene_type: "composition")
      expect(scene.fullscreen?).to be false
    end
  end
end
