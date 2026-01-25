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
class OverlaySceneElement < ApplicationRecord
  # Associations
  belongs_to :overlay_scene
  belongs_to :overlay_element

  # Validations
  validates :x, :y, numericality: {only_integer: true}, allow_nil: true
  validates :width, :height, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
  validates :z_index, numericality: {only_integer: true}, allow_nil: true

  # Scopes
  scope :ordered, -> { order(z_index: :asc) }

  # Merged settings: element defaults + scene overrides
  def effective_settings
    (overlay_element&.settings || {}).merge(overrides || {})
  end
end
