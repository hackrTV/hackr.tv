# == Schema Information
#
# Table name: overlay_scene_groups
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_overlay_scene_groups_on_slug  (slug) UNIQUE
#
class OverlaySceneGroup < ApplicationRecord
  # Associations
  has_many :overlay_scene_group_scenes, -> { order(position: :asc) }, dependent: :destroy
  has_many :overlay_scenes, through: :overlay_scene_group_scenes

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"}

  # Scopes
  scope :ordered, -> { order(name: :asc) }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Instance methods
  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
