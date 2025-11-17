FactoryBot.define do
  factory :radio_station do
    sequence(:name) { |n| "Station #{n}" }
    sequence(:slug) { |n| "station-#{n}" }
    description { "A test radio station" }
    genre { "Electronic" }
    color { "purple-168" }
    stream_url { "http://example.com/stream" }
    position { 0 }
  end
end
