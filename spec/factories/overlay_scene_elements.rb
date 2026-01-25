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
FactoryBot.define do
  factory :overlay_scene_element do
    association :overlay_scene
    association :overlay_element
    x { 0 }
    y { 0 }
    width { 400 }
    height { 100 }
    z_index { 1 }
    overrides { {} }
  end
end
