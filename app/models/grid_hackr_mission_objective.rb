# == Schema Information
#
# Table name: grid_hackr_mission_objectives
# Database name: primary
#
#  id                        :integer          not null, primary key
#  completed_at              :datetime
#  progress                  :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  grid_hackr_mission_id     :integer          not null
#  grid_mission_objective_id :integer          not null
#
# Indexes
#
#  index_hackr_mission_objs_on_hackr_mission  (grid_hackr_mission_id)
#  index_hackr_mission_objs_on_objective      (grid_mission_objective_id)
#  index_hackr_mission_objs_unique            (grid_hackr_mission_id,grid_mission_objective_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_mission_id      (grid_hackr_mission_id => grid_hackr_missions.id) ON DELETE => cascade
#  grid_mission_objective_id  (grid_mission_objective_id => grid_mission_objectives.id) ON DELETE => restrict
#
class GridHackrMissionObjective < ApplicationRecord
  belongs_to :grid_hackr_mission
  belongs_to :grid_mission_objective

  validates :grid_mission_objective_id, uniqueness: {scope: :grid_hackr_mission_id}
  validates :progress, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :completed, -> { where.not(completed_at: nil) }

  def completed?
    completed_at.present?
  end
end
