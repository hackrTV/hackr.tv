# == Schema Information
#
# Table name: overlay_scene_group_scenes
# Database name: primary
#
#  id                     :integer          not null, primary key
#  position               :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  overlay_scene_group_id :integer          not null
#  overlay_scene_id       :integer          not null
#
# Indexes
#
#  index_overlay_scene_group_scenes_on_overlay_scene_group_id  (overlay_scene_group_id)
#  index_overlay_scene_group_scenes_on_overlay_scene_id        (overlay_scene_id)
#  index_scene_group_scenes_position                           (overlay_scene_group_id,position)
#  index_scene_group_scenes_unique                             (overlay_scene_group_id,overlay_scene_id) UNIQUE
#
# Foreign Keys
#
#  overlay_scene_group_id  (overlay_scene_group_id => overlay_scene_groups.id)
#  overlay_scene_id        (overlay_scene_id => overlay_scenes.id)
#
class OverlaySceneGroupScene < ApplicationRecord
  belongs_to :overlay_scene_group
  belongs_to :overlay_scene

  # Validations
  validates :position, presence: true, numericality: {only_integer: true, greater_than: 0}
  validates :overlay_scene_id, uniqueness: {scope: :overlay_scene_group_id, message: "is already in this group"}

  # Callbacks
  before_validation :set_position, if: -> { position.nil? || position.zero? }

  private

  def set_position
    max_position = OverlaySceneGroupScene.where(overlay_scene_group_id: overlay_scene_group_id).maximum(:position) || 0
    self.position = max_position + 1
  end
end
