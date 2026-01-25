# == Schema Information
#
# Table name: artists
# Database name: primary
#
#  id          :integer          not null, primary key
#  artist_type :string           default("band"), not null
#  genre       :string
#  name        :string
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_artists_on_slug  (slug) UNIQUE
#
FactoryBot.define do
  factory :artist do
    name { "Test Artist" }
    sequence(:slug) { |n| "test-artist-#{n}" }
    genre { "Electronic" }

    trait :thecyberpulse do
      name { "The.CyberPul.se" }
      slug { "thecyberpulse" }
      genre { "Synthwave/Cyberpunk" }
    end

    trait :xeraen do
      name { "XERAEN" }
      slug { "xeraen" }
      genre { "Industrial/Dark Synth" }
    end
  end
end
