# == Schema Information
#
# Table name: grid_mission_rewards
# Database name: primary
#
#  id              :integer          not null, primary key
#  amount          :integer          default(0), not null
#  position        :integer          default(0), not null
#  quantity        :integer          default(1), not null
#  reward_type     :string           not null
#  target_slug     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_mission_id :integer          not null
#
# Indexes
#
#  index_grid_mission_rewards_on_grid_mission_id  (grid_mission_id)
#
# Foreign Keys
#
#  grid_mission_id  (grid_mission_id => grid_missions.id) ON DELETE => cascade
#
class GridMissionReward < ApplicationRecord
  belongs_to :grid_mission

  validates :reward_type, presence: true, inclusion: {in: GridMission::REWARD_TYPES}
  validates :amount, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :quantity, numericality: {only_integer: true, greater_than: 0}
end
