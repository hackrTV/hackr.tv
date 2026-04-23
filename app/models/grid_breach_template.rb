# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_breach_templates
# Database name: primary
#
#  id                    :integer          not null, primary key
#  base_detection_rate   :integer          default(5), not null
#  cooldown_max          :integer          default(600), not null
#  cooldown_min          :integer          default(300), not null
#  cred_reward           :integer          default(0), not null
#  description           :text
#  min_clearance         :integer          default(0), not null
#  name                  :string           not null
#  pnr_threshold         :integer          default(75), not null
#  position              :integer          default(0), not null
#  protocol_composition  :json             not null
#  published             :boolean          default(FALSE), not null
#  requires_item_slug    :string
#  requires_mission_slug :string
#  reward_table          :json             not null
#  slug                  :string           not null
#  tier                  :string           default("standard"), not null
#  xp_reward             :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_grid_breach_templates_on_published  (published)
#  index_grid_breach_templates_on_slug       (slug) UNIQUE
#  index_grid_breach_templates_on_tier       (tier)
#
class GridBreachTemplate < ApplicationRecord
  has_paper_trail

  TIERS = %w[ambient standard advanced elite world_event].freeze

  has_many :grid_breach_encounters, dependent: :restrict_with_error
  has_many :grid_hackr_breaches, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true,
    format: {with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens"}
  validates :name, presence: true
  validates :tier, presence: true, inclusion: {in: TIERS}
  validates :min_clearance, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :pnr_threshold, numericality: {only_integer: true, in: 1..100}
  validates :base_detection_rate, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :xp_reward, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :cred_reward, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :cooldown_min, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :cooldown_max, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validate :cooldown_range_valid
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:position, :name) }

  def to_param
    slug
  end

  def tier_label
    tier&.upcase&.tr("_", " ")
  end

  # Parse the protocol_composition JSON into a usable array of hashes.
  # Expected shape: [{"type": "trace", "count": 1, "health": 50, ...}, ...]
  def protocols
    composition = protocol_composition
    return [] unless composition.is_a?(Array)
    composition
  end

  # reward_table: Phase 2 — will drive variable loot drops on breach completion.
  # Schema/admin/YAML support it now; BreachService will read it once loot logic lands.

  private

  def cooldown_range_valid
    if cooldown_min.present? && cooldown_max.present? && cooldown_min > cooldown_max
      errors.add(:cooldown_max, "must be greater than or equal to cooldown_min")
    end
  end
end
