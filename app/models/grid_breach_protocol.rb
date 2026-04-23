# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_breach_protocols
# Database name: primary
#
#  id                   :integer          not null, primary key
#  charge_rounds        :integer          default(0), not null
#  health               :integer          not null
#  max_health           :integer          not null
#  meta                 :json             not null
#  position             :integer          not null
#  protocol_type        :string           not null
#  rerouted             :boolean          default(FALSE), not null
#  rounds_charging      :integer          default(0), not null
#  state                :string           default("idle"), not null
#  weakness             :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  grid_hackr_breach_id :integer          not null
#
# Indexes
#
#  index_breach_protocols_on_breach_and_position        (grid_hackr_breach_id,position) UNIQUE
#  index_grid_breach_protocols_on_grid_hackr_breach_id  (grid_hackr_breach_id)
#
# Foreign Keys
#
#  grid_hackr_breach_id  (grid_hackr_breach_id => grid_hackr_breaches.id) ON DELETE => cascade
#
class GridBreachProtocol < ApplicationRecord
  PROTOCOL_TYPES = %w[trace feedback lock adapt].freeze
  PROTOCOL_STATES = %w[idle charging active destroyed].freeze

  belongs_to :grid_hackr_breach

  validates :protocol_type, presence: true, inclusion: {in: PROTOCOL_TYPES}
  validates :state, presence: true, inclusion: {in: PROTOCOL_STATES}
  validates :health, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :max_health, numericality: {only_integer: true, greater_than: 0}
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :alive, -> { where.not(state: "destroyed") }
  scope :ordered, -> { order(:position) }

  def destroyed?
    state == "destroyed"
  end

  def alive?
    !destroyed?
  end

  def type_label
    protocol_type.upcase
  end

  def analyze_level
    (meta || {})["analyze_level"].to_i
  end

  def analyze_level=(level)
    self.meta = (meta || {}).merge("analyze_level" => level)
  end
end
