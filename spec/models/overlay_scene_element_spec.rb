# == Schema Information
#
# Table name: overlay_scene_elements
# Database name: primary
#
#  id                 :integer          not null, primary key
#  height             :integer
#  overrides          :json
#  width              :integer
#  x                  :integer          default(0)
#  y                  :integer          default(0)
#  z_index            :integer          default(0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  overlay_element_id :integer          not null
#  overlay_scene_id   :integer          not null
#
# Indexes
#
#  idx_scene_elements_composite                        (overlay_scene_id,overlay_element_id)
#  index_overlay_scene_elements_on_overlay_element_id  (overlay_element_id)
#  index_overlay_scene_elements_on_overlay_scene_id    (overlay_scene_id)
#  index_overlay_scene_elements_on_z_index             (z_index)
#
# Foreign Keys
#
#  overlay_element_id  (overlay_element_id => overlay_elements.id)
#  overlay_scene_id    (overlay_scene_id => overlay_scenes.id)
#
require "rails_helper"

RSpec.describe OverlaySceneElement, type: :model do
  describe "associations" do
    it { should belong_to(:overlay_scene) }
    it { should belong_to(:overlay_element) }
  end

  describe "validations" do
    it { should validate_numericality_of(:x).only_integer.allow_nil }
    it { should validate_numericality_of(:y).only_integer.allow_nil }
    it { should validate_numericality_of(:width).only_integer.is_greater_than(0).allow_nil }
    it { should validate_numericality_of(:height).only_integer.is_greater_than(0).allow_nil }
    it { should validate_numericality_of(:z_index).only_integer.allow_nil }
  end

  describe "scopes" do
    it ".ordered orders by z_index" do
      scene = create(:overlay_scene)
      element = create(:overlay_element)

      element3 = create(:overlay_scene_element, overlay_scene: scene, overlay_element: element, z_index: 3)
      element1 = create(:overlay_scene_element, overlay_scene: scene, overlay_element: element, z_index: 1)
      element2 = create(:overlay_scene_element, overlay_scene: scene, overlay_element: element, z_index: 2)

      ordered = OverlaySceneElement.ordered
      expect(ordered.to_a).to eq([element1, element2, element3])
    end
  end

  describe "#effective_settings" do
    it "merges element settings with overrides" do
      element = create(:overlay_element, settings: {"max_items" => 5, "color" => "red"})
      scene = create(:overlay_scene)
      scene_element = create(:overlay_scene_element,
        overlay_scene: scene,
        overlay_element: element,
        overrides: {"max_items" => 10, "new_setting" => "value"})

      settings = scene_element.effective_settings
      expect(settings["max_items"]).to eq(10)
      expect(settings["color"]).to eq("red")
      expect(settings["new_setting"]).to eq("value")
    end

    it "returns element settings when no overrides" do
      element = create(:overlay_element, settings: {"max_items" => 5})
      scene = create(:overlay_scene)
      scene_element = create(:overlay_scene_element,
        overlay_scene: scene,
        overlay_element: element,
        overrides: nil)

      expect(scene_element.effective_settings).to eq({"max_items" => 5})
    end

    it "handles nil element settings" do
      element = create(:overlay_element, settings: nil)
      scene = create(:overlay_scene)
      scene_element = create(:overlay_scene_element,
        overlay_scene: scene,
        overlay_element: element,
        overrides: {"key" => "value"})

      expect(scene_element.effective_settings).to eq({"key" => "value"})
    end
  end
end
