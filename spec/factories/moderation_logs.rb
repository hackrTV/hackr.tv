FactoryBot.define do
  factory :moderation_log do
    association :actor, factory: :grid_hackr
    association :target, factory: :grid_hackr
    action { "squelch" }
    reason { "Test moderation action" }
    duration_minutes { nil }

    trait :squelch do
      action { "squelch" }
    end

    trait :blackout do
      action { "blackout" }
    end

    trait :lift do
      action { "lift_punishment" }
    end

    trait :drop_packet do
      action { "drop_packet" }
      association :chat_message
    end

    trait :with_duration do
      duration_minutes { 30 }
    end
  end
end
