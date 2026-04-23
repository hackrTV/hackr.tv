# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_hackr_breaches
# Database name: primary
#
#  id                       :integer          not null, primary key
#  actions_remaining        :integer          default(1), not null
#  actions_this_round       :integer          default(1), not null
#  detection_level          :integer          default(0), not null
#  ended_at                 :datetime
#  inspiration              :integer          default(0), not null
#  pnr_threshold            :integer          default(75), not null
#  reward_multiplier        :decimal(5, 4)    default(1.0), not null
#  round_number             :integer          default(1), not null
#  started_at               :datetime         not null
#  state                    :string           default("active"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  grid_breach_encounter_id :integer
#  grid_breach_template_id  :integer          not null
#  grid_hackr_id            :integer          not null
#  origin_room_id           :integer
#
# Indexes
#
#  index_grid_hackr_breaches_on_grid_breach_encounter_id  (grid_breach_encounter_id)
#  index_grid_hackr_breaches_on_grid_breach_template_id   (grid_breach_template_id)
#  index_grid_hackr_breaches_on_grid_hackr_id             (grid_hackr_id)
#  index_grid_hackr_breaches_on_state                     (state)
#  index_hackr_breaches_one_active_per_hackr              (grid_hackr_id) UNIQUE WHERE state = 'active'
#
# Foreign Keys
#
#  grid_breach_encounter_id  (grid_breach_encounter_id => grid_breach_encounters.id) ON DELETE => nullify
#  grid_breach_template_id   (grid_breach_template_id => grid_breach_templates.id) ON DELETE => restrict
#  grid_hackr_id             (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#  origin_room_id            (origin_room_id => grid_rooms.id) ON DELETE => nullify
#
class GridHackrBreach < ApplicationRecord
  STATES = %w[active success failure jacked_out].freeze

  belongs_to :grid_hackr
  belongs_to :grid_breach_template
  belongs_to :grid_breach_encounter, optional: true
  belongs_to :origin_room, class_name: "GridRoom", optional: true
  has_many :grid_breach_protocols, dependent: :destroy
  has_many :grid_hackr_breach_logs, dependent: :destroy

  validates :state, presence: true, inclusion: {in: STATES}
  validates :detection_level, numericality: {only_integer: true, in: 0..100}
  validates :pnr_threshold, numericality: {only_integer: true, in: 1..100}
  validates :round_number, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :inspiration, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :actions_remaining, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :actions_this_round, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :active, -> { where(state: "active") }

  def active?
    state == "active"
  end

  def pnr_crossed?
    detection_level >= pnr_threshold
  end

  def all_protocols_destroyed?
    grid_breach_protocols.where.not(state: "destroyed").none?
  end
end
