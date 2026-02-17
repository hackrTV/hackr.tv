# == Schema Information
#
# Table name: hackr_streams
# Database name: primary
#
#  id         :integer          not null, primary key
#  ended_at   :datetime
#  is_live    :boolean          default(FALSE), not null
#  live_url   :string
#  started_at :datetime
#  title      :string
#  track_slug :string
#  vod_url    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  artist_id  :integer          not null
#
# Indexes
#
#  index_hackr_streams_on_artist_id  (artist_id)
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
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
