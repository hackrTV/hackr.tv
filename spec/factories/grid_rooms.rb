# == Schema Information
#
# Table name: grid_rooms
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  min_clearance       :integer          default(0), not null
#  name                :string
#  room_type           :string
#  slug                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ambient_playlist_id :integer
#  grid_zone_id        :integer          not null
#
# Indexes
#
#  index_grid_rooms_on_ambient_playlist_id  (ambient_playlist_id)
#  index_grid_rooms_on_grid_zone_id         (grid_zone_id)
#  index_grid_rooms_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  ambient_playlist_id  (ambient_playlist_id => zone_playlists.id)
#
FactoryBot.define do
  factory :grid_room do
    sequence(:name) { |n| "Room #{n}" }
    description { "A room in THE PULSE GRID" }
    association :grid_zone
    room_type { "transit" }

    trait :hub do
      room_type { "hub" }
    end

    trait :faction_base do
      room_type { "faction_base" }
    end

    trait :govcorp do
      room_type { "govcorp" }
    end

    trait :safe_zone do
      room_type { "safe_zone" }
    end

    trait :shop do
      room_type { "shop" }
    end

    trait :danger_zone do
      room_type { "danger_zone" }
    end

    trait :prism do
      room_type { "prism" }
    end

    trait :dream do
      room_type { "dream" }
    end
  end
end
