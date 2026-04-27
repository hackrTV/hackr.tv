# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_hackr_breach_logs
# Database name: primary
#
#  id                   :integer          not null, primary key
#  action_type          :string           not null
#  program_slug         :string
#  result               :json             not null
#  round                :integer          not null
#  target               :string
#  created_at           :datetime         not null
#  grid_hackr_breach_id :integer          not null
#
# Indexes
#
#  index_breach_logs_on_breach_and_round                 (grid_hackr_breach_id,round)
#  index_grid_hackr_breach_logs_on_grid_hackr_breach_id  (grid_hackr_breach_id)
#
# Foreign Keys
#
#  grid_hackr_breach_id  (grid_hackr_breach_id => grid_hackr_breaches.id) ON DELETE => cascade
#
class GridHackrBreachLog < ApplicationRecord
  ACTION_TYPES = %w[exec analyze reroute jackout use system interface probe].freeze

  belongs_to :grid_hackr_breach

  validates :round, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :action_type, presence: true, inclusion: {in: ACTION_TYPES}

  scope :ordered, -> { order(:created_at) }
  scope :for_round, ->(round) { where(round: round) }
end
