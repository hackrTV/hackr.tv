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
