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
