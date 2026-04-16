# == Schema Information
#
# Table name: grid_hackr_missions
# Database name: primary
#
#  id              :integer          not null, primary key
#  accepted_at     :datetime         not null
#  completed_at    :datetime
#  status          :string           default("active"), not null
#  turn_in_count   :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer          not null
#  grid_mission_id :integer          not null
#
# Indexes
#
#  index_grid_hackr_missions_on_grid_hackr_id    (grid_hackr_id)
#  index_grid_hackr_missions_on_grid_mission_id  (grid_mission_id)
#  index_hackr_missions_on_hackr_and_status      (grid_hackr_id,status)
#  index_hackr_missions_unique_active            (grid_hackr_id,grid_mission_id) UNIQUE WHERE status = 'active'
#
# Foreign Keys
#
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#  grid_mission_id  (grid_mission_id => grid_missions.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :grid_hackr_mission do
    association :grid_hackr
    association :grid_mission
    status { "active" }
    accepted_at { Time.current }
    turn_in_count { 0 }

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
      turn_in_count { 1 }
    end
  end
end
