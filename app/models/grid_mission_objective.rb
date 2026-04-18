# == Schema Information
#
# Table name: grid_mission_objectives
# Database name: primary
#
#  id              :integer          not null, primary key
#  label           :string           not null
#  objective_type  :string           not null
#  position        :integer          default(0), not null
#  target_count    :integer          default(1), not null
#  target_slug     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_mission_id :integer          not null
#
# Indexes
#
#  index_grid_mission_objectives_on_grid_mission_id  (grid_mission_id)
#  index_mission_objectives_on_mission_and_position  (grid_mission_id,position)
#
# Foreign Keys
#
#  grid_mission_id  (grid_mission_id => grid_missions.id) ON DELETE => cascade
#
class GridMissionObjective < ApplicationRecord
  has_paper_trail

  belongs_to :grid_mission
  has_many :grid_hackr_mission_objectives, dependent: :restrict_with_exception

  validates :objective_type, presence: true, inclusion: {in: GridMission::OBJECTIVE_TYPES}
  validates :label, presence: true
  validates :target_count, numericality: {only_integer: true, greater_than: 0}
end
