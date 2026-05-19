# == Schema Information
#
# Table name: hackr_streams
# Database name: primary
#
#  id           :integer          not null, primary key
#  cancelled_at :datetime
#  ended_at     :datetime
#  is_live      :boolean          default(FALSE), not null
#  live_url     :string
#  scheduled_at :datetime
#  started_at   :datetime
#  title        :string
#  track_slug   :string
#  vod_url      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer          not null
#
# Indexes
#
#  index_hackr_streams_on_artist_id     (artist_id)
#  index_hackr_streams_on_scheduled_at  (scheduled_at)
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

    trait :scheduled do
      scheduled_at { 2.hours.from_now }
      started_at { nil }
      ended_at { nil }
      is_live { false }
      live_url { "https://www.youtube.com/embed/scheduled123" }
      title { "Scheduled Stream" }
    end

    trait :starting_soon do
      scheduled_at { 10.minutes.ago }
      started_at { nil }
      ended_at { nil }
      is_live { false }
      live_url { "https://www.youtube.com/embed/soon123" }
      title { "Starting Soon Stream" }
    end

    trait :expired_schedule do
      scheduled_at { 2.hours.ago }
      started_at { nil }
      ended_at { nil }
      is_live { false }
      title { "Expired Stream" }
    end

    trait :cancelled do
      scheduled_at { 2.hours.from_now }
      cancelled_at { 1.hour.ago }
      started_at { nil }
      ended_at { nil }
      is_live { false }
      title { "Cancelled Stream" }
    end
  end
end
