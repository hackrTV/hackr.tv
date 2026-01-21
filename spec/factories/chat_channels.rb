FactoryBot.define do
  factory :chat_channel do
    sequence(:slug) { |n| "channel#{n}" }
    sequence(:name) { |n| "#channel#{n}" }
    description { "A test chat channel" }
    is_active { true }
    requires_livestream { false }
    slow_mode_seconds { 0 }
    minimum_role { "operative" }

    trait :inactive do
      is_active { false }
    end

    trait :livestream_only do
      requires_livestream { true }
    end

    trait :slow_mode do
      slow_mode_seconds { 30 }
    end

    trait :operator_only do
      minimum_role { "operator" }
    end

    trait :admin_only do
      minimum_role { "admin" }
    end
  end
end
