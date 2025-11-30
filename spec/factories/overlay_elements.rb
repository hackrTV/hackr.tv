FactoryBot.define do
  factory :overlay_element do
    sequence(:name) { |n| "Element #{n}" }
    sequence(:slug) { |n| "element-#{n}" }
    element_type { "now_playing" }
    active { true }
    settings { {} }

    trait :inactive do
      active { false }
    end

    trait :pulsewire_feed do
      element_type { "pulsewire_feed" }
    end

    trait :grid_activity do
      element_type { "grid_activity" }
    end

    trait :alert do
      element_type { "alert" }
    end

    trait :lower_third do
      element_type { "lower_third" }
    end

    trait :codex_entry do
      element_type { "codex_entry" }
    end

    trait :ticker_top do
      element_type { "ticker_top" }
    end

    trait :ticker_bottom do
      element_type { "ticker_bottom" }
    end
  end
end
