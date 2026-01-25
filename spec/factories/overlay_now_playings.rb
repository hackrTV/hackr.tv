# == Schema Information
#
# Table name: overlay_now_playing
# Database name: primary
#
#  id            :integer          not null, primary key
#  custom_artist :string
#  custom_title  :string
#  is_live       :boolean          default(FALSE)
#  paused        :boolean          default(FALSE), not null
#  started_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  track_id      :integer
#
# Indexes
#
#  index_overlay_now_playing_on_track_id  (track_id)
#
# Foreign Keys
#
#  track_id  (track_id => tracks.id)
#
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
