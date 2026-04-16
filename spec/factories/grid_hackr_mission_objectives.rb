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
FactoryBot.define do
  factory :grid_hackr_mission_objective do
    association :grid_hackr_mission
    association :grid_mission_objective
    progress { 0 }
    completed_at { nil }

    trait :completed do
      progress { 1 }
      completed_at { Time.current }
    end
  end
end
