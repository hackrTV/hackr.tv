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
