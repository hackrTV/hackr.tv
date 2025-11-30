FactoryBot.define do
  factory :overlay_now_playing do
    track { nil }
    custom_title { nil }
    custom_artist { nil }
    started_at { nil }
    paused { false }
    is_live { false }

    trait :with_track do
      association :track
      started_at { Time.current }
    end

    trait :with_custom do
      custom_title { "Custom Track Title" }
      custom_artist { "Custom Artist" }
      started_at { Time.current }
    end

    trait :paused do
      paused { true }
    end

    trait :live do
      is_live { true }
    end
  end
end
