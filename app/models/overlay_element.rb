class OverlayElement < ApplicationRecord
  ELEMENT_TYPES = %w[
    now_playing
    pulsewire_feed
    grid_activity
    alert
    lower_third
    codex_entry
    ticker_top
    ticker_bottom
  ].freeze

  # Associations
  has_many :overlay_scene_elements, dependent: :destroy
  has_many :overlay_scenes, through: :overlay_scene_elements

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"}
  validates :element_type, presence: true, inclusion: {in: ELEMENT_TYPES}

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(element_type: type) }

  # Instance methods
  def to_param
    slug
  end

  # Settings accessors for common element-specific configurations
  def codex_entry_slug
    settings["codex_entry_slug"]
  end

  def max_items
    settings["max_items"] || 5
  end

  def ticker_slug
    settings["ticker_slug"]
  end

  def lower_third_slug
    settings["lower_third_slug"]
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
