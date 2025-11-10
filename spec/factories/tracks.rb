FactoryBot.define do
  factory :track do
    association :artist
    association :album
    title { "Test Track" }
    sequence(:slug) { |n| "test-track-#{n}" }
    track_number { 1 }
    release_date { Date.today }
    duration { "3:45" }
    featured { false }
    streaming_links { {spotify: "https://spotify.com/track/123", youtube: "https://youtube.com/watch?v=123"} }
    videos { {music: "https://youtube.com/watch?v=abc"} }
    lyrics { "Test lyrics\nVerse 1\n[Chorus]" }

    trait :featured do
      featured { true }
    end

    trait :without_streaming_links do
      streaming_links { nil }
    end

    trait :without_videos do
      videos { nil }
    end

    trait :without_lyrics do
      lyrics { nil }
    end

    trait :minimal do
      release_date { nil }
      duration { nil }
      streaming_links { nil }
      videos { nil }
      lyrics { nil }
      track_number { nil }
    end
  end
end
