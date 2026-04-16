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
FactoryBot.define do
  factory :grid_mission_objective do
    association :grid_mission
    sequence(:position) { |n| n }
    objective_type { "visit_room" }
    label { "Reach the target room" }
    target_slug { "test-room" }
    target_count { 1 }

    trait :talk_npc do
      objective_type { "talk_npc" }
      target_slug { "TestNPC" }
      label { "Talk to TestNPC" }
    end

    trait :collect_item do
      objective_type { "collect_item" }
      target_slug { "Test Item" }
      label { "Collect the Test Item" }
    end

    trait :deliver_item do
      objective_type { "deliver_item" }
      target_slug { "Test Item" }
      label { "Deliver the Test Item" }
    end

    trait :spend_cred do
      objective_type { "spend_cred" }
      target_slug { nil }
      target_count { 100 }
      label { "Spend 100 CRED" }
    end

    trait :reach_clearance do
      objective_type { "reach_clearance" }
      target_slug { nil }
      target_count { 5 }
      label { "Reach clearance 5" }
    end
  end
end
