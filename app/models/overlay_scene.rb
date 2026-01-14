class OverlayScene < ApplicationRecord
  SCENE_TYPES = %w[fullscreen composition].freeze

  # Associations
  has_many :overlay_scene_elements, dependent: :destroy
  has_many :overlay_elements, through: :overlay_scene_elements
  has_many :overlay_scene_group_scenes, dependent: :destroy
  has_many :overlay_scene_groups, through: :overlay_scene_group_scenes

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"}
  validates :scene_type, presence: true, inclusion: {in: SCENE_TYPES}
  validates :width, :height, numericality: {greater_than: 0}

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :fullscreen, -> { where(scene_type: "fullscreen") }
  scope :compositions, -> { where(scene_type: "composition") }
  scope :ordered, -> { order(position: :asc, name: :asc) }

  # Instance methods
  def to_param
    slug
  end

  def fullscreen?
    scene_type == "fullscreen"
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
