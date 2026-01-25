# == Schema Information
#
# Table name: grid_zones
# Database name: primary
#
#  id                  :integer          not null, primary key
#  color_scheme        :string
#  description         :text
#  name                :string
#  slug                :string
#  zone_type           :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ambient_playlist_id :integer
#  grid_faction_id     :integer
#
# Indexes
#
#  index_grid_zones_on_ambient_playlist_id  (ambient_playlist_id)
#
# Foreign Keys
#
#  ambient_playlist_id  (ambient_playlist_id => zone_playlists.id)
#
FactoryBot.define do
  factory :grid_zone do
    sequence(:name) { |n| "Zone #{n}" }
    sequence(:slug) { |n| "zone_#{n}" }
    description { "A test zone in THE PULSE GRID" }
    zone_type { "transit" }
    color_scheme { "gray/neon green" }
    grid_faction { nil }

    trait :faction_base do
      zone_type { "faction_base" }
      color_scheme { "purple" }
      association :grid_faction
    end

    trait :govcorp do
      zone_type { "govcorp" }
      color_scheme { "red" }
    end

    trait :residential do
      zone_type { "residential" }
      color_scheme { "blue" }
    end

    trait :special do
      zone_type { "special" }
      color_scheme { "cyan" }
    end
  end
end
