FactoryBot.define do
  factory :overlay_lower_third do
    sequence(:name) { |n| "Lower Third #{n}" }
    sequence(:slug) { |n| "lower-third-#{n}" }
    primary_text { "Primary Text" }
    secondary_text { "Secondary Text" }
    logo_url { nil }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_logo do
      logo_url { "https://example.com/logo.png" }
    end
  end
end
