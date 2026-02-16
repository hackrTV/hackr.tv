# == Schema Information
#
# Table name: releases
# Database name: primary
#
#  id             :integer          not null, primary key
#  catalog_number :string
#  classification :string
#  credits        :text
#  description    :text
#  label          :string
#  media_format   :string
#  name           :string           not null
#  notes          :text
#  release_date   :date
#  release_type   :string
#  slug           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  artist_id      :integer          not null
#
# Indexes
#
#  index_releases_on_artist_id           (artist_id)
#  index_releases_on_artist_id_and_slug  (artist_id,slug) UNIQUE
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
FactoryBot.define do
  factory :release do
    association :artist
    name { "Test Release" }
    sequence(:slug) { |n| "test-release-#{n}" }
    release_type { "album" }
    release_date { Date.today }
    description { "A test release description" }

    trait :single do
      release_type { "single" }
    end

    trait :ep do
      release_type { "ep" }
    end

    trait :without_release_date do
      release_date { nil }
    end

    trait :with_cover do
      after(:build) do |release|
        release.cover_image.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
          filename: "test_cover.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end
