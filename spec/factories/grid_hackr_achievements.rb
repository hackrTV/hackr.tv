FactoryBot.define do
  factory :grid_hackr_achievement do
    association :grid_hackr
    association :grid_achievement
    awarded_at { Time.current }
  end
end
