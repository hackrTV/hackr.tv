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
