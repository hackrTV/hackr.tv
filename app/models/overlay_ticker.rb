# == Schema Information
#
# Table name: overlay_tickers
# Database name: primary
#
#  id           :integer          not null, primary key
#  active       :boolean          default(TRUE)
#  content      :text             not null
#  content_type :string           default("static"), not null
#  direction    :string           default("left")
#  feed_source  :string
#  name         :string           not null
#  slug         :string           not null
#  speed        :integer          default(50)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_overlay_tickers_on_active  (active)
#  index_overlay_tickers_on_slug    (slug) UNIQUE
#
class OverlayTicker < ApplicationRecord
  POSITIONS = %w[top bottom].freeze
  DIRECTIONS = %w[left right].freeze
  CONTENT_TYPES = %w[static dynamic].freeze
  FEED_SOURCES = %w[pulsewire world_events now_playing api].freeze

  has_paper_trail

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"}
  validates :content, presence: true, if: :static?
  validates :speed, numericality: {greater_than: 0}
  validates :direction, inclusion: {in: DIRECTIONS}
  validates :content_type, presence: true, inclusion: {in: CONTENT_TYPES}
  validates :feed_source, inclusion: {in: FEED_SOURCES}, allow_blank: true
  validates :feed_source, presence: true, if: :dynamic?

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_validation :set_default_content, if: -> { dynamic? && content.blank? }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(name: :asc) }

  # Instance methods
  def to_param
    slug
  end

  def static?
    content_type == "static"
  end

  def dynamic?
    content_type == "dynamic"
  end

  # Broadcast update to overlay channel
  def broadcast_update!
    ActionCable.server.broadcast("overlay_updates", {
      type: "ticker_updated",
      data: {
        slug: slug,
        content: content,
        content_type: content_type,
        feed_source: feed_source,
        speed: speed,
        direction: direction,
        active: active
      }
    })
  end

  private

  def set_default_content
    self.content = "Awaiting #{feed_source} feed..."
  end

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
