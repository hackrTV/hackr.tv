FactoryBot.define do
  factory :grid_shop_listing do
    sequence(:name) { |n| "Shop Item #{n}" }
    description { "An item for sale" }
    association :grid_mob, :vendor
    item_type { "consumable" }
    rarity { "common" }
    base_price { 100 }
    sell_price { 50 }
    stock { 10 }
    max_stock { 10 }
    restock_amount { 1 }
    restock_interval_hours { 24 }
    active { true }
    rotation_pool { false }
    min_clearance { 0 }
    properties { {} }

    trait :unlimited do
      stock { nil }
      max_stock { nil }
    end

    trait :out_of_stock do
      stock { 0 }
    end

    trait :rotation do
      rotation_pool { true }
    end

    trait :black_market do
      min_clearance { 10 }
      rarity { "rare" }
      base_price { 800 }
      sell_price { 400 }
      association :grid_mob, :vendor, vendor_config: {"shop_type" => "black_market"}
    end

    trait :component do
      item_type { "component" }
      properties { {"slot" => "gpu", "rate_multiplier" => 1.5} }
    end

    trait :consumable do
      item_type { "consumable" }
      properties { {"effect_type" => "heal", "amount" => 30} }
    end
  end
end
