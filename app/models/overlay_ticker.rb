# == Schema Information
#
# Table name: overlay_tickers
# Database name: primary
#
#  id         :integer          not null, primary key
#  active     :boolean          default(TRUE)
#  content    :text             not null
#  direction  :string           default("left")
#  name       :string           not null
#  slug       :string           not null
#  speed      :integer          default(50)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_overlay_tickers_on_active  (active)
#  index_overlay_tickers_on_slug    (slug) UNIQUE
#
class OverlayTicker < ApplicationRecord
  POSITIONS = %w[top bottom].freeze
  DIRECTIONS = %w[left right].freeze

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, inclusion: {in: POSITIONS}
  validates :content, presence: true
  validates :speed, numericality: {greater_than: 0}
  validates :direction, inclusion: {in: DIRECTIONS}

  # Scopes
  scope :active, -> { where(active: true) }

  # Find by position
  def self.top
    find_by(slug: "top")
  end

  def self.bottom
    find_by(slug: "bottom")
  end

  # Broadcast update to overlay channel
  def broadcast_update!
    ActionCable.server.broadcast("overlay_updates", {
      type: "ticker_updated",
      data: {
        slug: slug,
        content: content,
        speed: speed,
        direction: direction,
        active: active
      }
    })
  end
end
