FactoryBot.define do
  factory :grid_hackr do
    sequence(:hackr_alias) { |n| "Hackr#{n}" }
    password { "password123" }
    role { "operative" }
    current_room { nil }

    trait :operator do
      role { "operator" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :online do
      association :current_room, factory: :grid_room
      last_activity_at { Time.current }
    end
  end
end
