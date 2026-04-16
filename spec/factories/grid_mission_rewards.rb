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
FactoryBot.define do
  factory :grid_mission_reward do
    association :grid_mission
    sequence(:position) { |n| n }
    reward_type { "xp" }
    amount { 50 }
    target_slug { nil }
    quantity { 1 }

    trait :cred do
      reward_type { "cred" }
      amount { 25 }
    end

    trait :faction_rep do
      reward_type { "faction_rep" }
      amount { 10 }
      target_slug { "hackrcore" }
    end

    trait :item_grant do
      reward_type { "item_grant" }
      target_slug { "Test Reward Item" }
      amount { 5 }
      quantity { 1 }
    end

    trait :grant_achievement do
      reward_type { "grant_achievement" }
      target_slug { "test-achievement" }
      amount { 0 }
    end
  end
end
