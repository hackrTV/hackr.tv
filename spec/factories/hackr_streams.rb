FactoryBot.define do
  factory :hackr_stream do
    artist { nil }
    is_live { false }
    live_url { "MyString" }
    vod_url { nil }
    title { "MyString" }
    started_at { "2025-11-22 13:54:04" }
    ended_at { "2025-11-22 13:54:04" }
  end
end
