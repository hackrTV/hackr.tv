FactoryBot.define do
  factory :hackr_stream do
    association :artist
    is_live { false }
    live_url { nil }
    vod_url { nil }
    title { "Test Stream" }
    started_at { 1.day.ago }
    ended_at { nil }

    trait :live do
      is_live { true }
      live_url { "https://www.youtube.com/embed/test123" }
      started_at { 1.hour.ago }
      ended_at { nil }
    end

    trait :with_vod do
      vod_url { "https://www.youtube.com/embed/vod123" }
      started_at { 1.day.ago }
      ended_at { 1.day.ago + 2.hours }
    end

    trait :livestream_with_vod do
      live_url { "https://www.youtube.com/embed/live123" }
      vod_url { "https://www.youtube.com/embed/vod123" }
      started_at { 1.day.ago }
      ended_at { 1.day.ago + 2.hours }
    end
  end
end
