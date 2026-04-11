FactoryBot.define do
  factory :grid_item do
    sequence(:name) { |n| "Item #{n}" }
    description { "A grid item" }
    item_type { "tool" }
    rarity { "common" }
    value { 10 }
    quantity { 1 }
    properties { {} }

    # By default, items are in a room
    association :room, factory: :grid_room

    trait :in_inventory do
      room { nil }
      association :grid_hackr
    end

    trait :component do
      item_type { "component" }
      properties { {"slot" => "gpu", "rate_multiplier" => 1.0} }
    end

    trait :consumable do
      item_type { "consumable" }
      properties { {"effect_type" => "heal", "amount" => 25} }
    end
  end
end
