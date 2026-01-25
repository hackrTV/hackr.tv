# == Schema Information
#
# Table name: overlay_lower_thirds
# Database name: primary
#
#  id             :integer          not null, primary key
#  active         :boolean          default(TRUE)
#  logo_url       :string
#  name           :string           not null
#  primary_text   :string           not null
#  secondary_text :string
#  slug           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_overlay_lower_thirds_on_active  (active)
#  index_overlay_lower_thirds_on_slug    (slug) UNIQUE
#
class OverlayLowerThird < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"}
  validates :primary_text, presence: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :active, -> { where(active: true) }

  # Instance methods
  def to_param
    slug
  end

  # Broadcast update to overlay channel
  def broadcast_update!
    ActionCable.server.broadcast("overlay_updates", {
      type: "lower_third_updated",
      data: {
        slug: slug,
        primary_text: primary_text,
        secondary_text: secondary_text,
        logo_url: logo_url,
        active: active
      }
    })
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
