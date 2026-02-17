# == Schema Information
#
# Table name: tracks
# Database name: primary
#
#  id                  :integer          not null, primary key
#  cover_image         :string
#  duration            :string
#  featured            :boolean          default(FALSE)
#  lyrics              :text
#  release_date        :date
#  show_in_pulse_vault :boolean          default(TRUE), not null
#  slug                :string
#  streaming_links     :text
#  title               :string
#  track_number        :integer
#  videos              :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  artist_id           :integer          not null
#  release_id          :integer          not null
#
# Indexes
#
#  index_tracks_on_artist_id           (artist_id)
#  index_tracks_on_artist_id_and_slug  (artist_id,slug) UNIQUE
#  index_tracks_on_featured            (featured)
#  index_tracks_on_release_date        (release_date)
#  index_tracks_on_release_id          (release_id)
#
# Foreign Keys
#
#  artist_id   (artist_id => artists.id)
#  release_id  (release_id => releases.id)
#
FactoryBot.define do
  factory :track do
    association :artist
    association :release
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
