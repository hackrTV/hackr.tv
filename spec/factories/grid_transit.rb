# frozen_string_literal: true

FactoryBot.define do
  factory :grid_transit_type do
    sequence(:slug) { |n| "transit-type-#{n}" }
    sequence(:name) { |n| "Transit Type #{n}" }
    category { "public" }
    base_fare { 5 }
    min_clearance { 0 }
    published { true }
    position { 0 }

    trait :public_type do
      category { "public" }
      base_fare { 5 }
    end

    trait :private_type do
      category { "private" }
      base_fare { 20 }
    end

    trait :slipstream_type do
      category { "slipstream" }
      base_fare { 0 }
      min_clearance { 15 }
      slug { "slipstream" }
      name { "Slipstream" }
    end
  end

  factory :grid_transit_route do
    sequence(:slug) { |n| "transit-route-#{n}" }
    sequence(:name) { |n| "Transit Route #{n}" }
    association :grid_transit_type
    association :grid_region
    active { true }
    position { 0 }
  end

  factory :grid_transit_stop do
    association :grid_transit_route
    association :grid_room
    sequence(:position) { |n| n }
    is_terminus { false }
  end

  factory :grid_slipstream_route do
    sequence(:slug) { |n| "slip-route-#{n}" }
    sequence(:name) { |n| "Slipstream Route #{n}" }
    association :origin_region, factory: :grid_region
    association :destination_region, factory: :grid_region
    association :origin_room, factory: :grid_room
    association :destination_room, factory: :grid_room
    min_clearance { 15 }
    base_heat_cost { 10 }
    detection_risk_base { 15 }
    active { true }
    position { 0 }
  end

  factory :grid_slipstream_leg do
    association :grid_slipstream_route
    sequence(:position) { |n| n }
    sequence(:name) { |n| "Leg #{n}" }
    description { "A corridor junction." }
    fork_options do
      [
        {"key" => "A", "label" => "Maintenance Corridor", "risk_modifier" => -5, "description" => "Low risk, slow."},
        {"key" => "B", "label" => "Freight Car", "risk_modifier" => 10, "description" => "High risk, fast."}
      ]
    end
  end
end
