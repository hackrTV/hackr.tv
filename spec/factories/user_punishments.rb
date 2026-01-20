FactoryBot.define do
  factory :user_punishment do
    association :grid_hackr
    association :issued_by, factory: :grid_hackr
    punishment_type { "squelch" }
    reason { "Test punishment" }
    expires_at { nil }

    trait :squelch do
      punishment_type { "squelch" }
    end

    trait :blackout do
      punishment_type { "blackout" }
    end

    trait :temporary do
      expires_at { 30.minutes.from_now }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end
  end
end
