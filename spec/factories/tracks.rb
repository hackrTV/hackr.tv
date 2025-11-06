FactoryBot.define do
  factory :track do
    association :artist
    title { "Test Track" }
    sequence(:slug) { |n| "test-track-#{n}" }
    album { "Test Album" }
    album_type { "single" }
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
      album { nil }
      album_type { nil }
      release_date { nil }
      duration { nil }
      streaming_links { nil }
      videos { nil }
      lyrics { nil }
    end
  end
end
