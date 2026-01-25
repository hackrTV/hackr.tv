# == Schema Information
#
# Table name: albums
# Database name: primary
#
#  id           :integer          not null, primary key
#  album_type   :string
#  description  :text
#  name         :string           not null
#  release_date :date
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer          not null
#
# Indexes
#
#  index_albums_on_artist_id           (artist_id)
#  index_albums_on_artist_id_and_slug  (artist_id,slug) UNIQUE
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
FactoryBot.define do
  factory :album do
    association :artist
    name { "Test Album" }
    sequence(:slug) { |n| "test-album-#{n}" }
    album_type { "album" }
    release_date { Date.today }
    description { "A test album description" }

    trait :single do
      album_type { "single" }
    end

    trait :ep do
      album_type { "ep" }
    end

    trait :without_release_date do
      release_date { nil }
    end

    trait :with_cover do
      after(:build) do |album|
        album.cover_image.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
          filename: "test_cover.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end
