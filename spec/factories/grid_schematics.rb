FactoryBot.define do
  factory :grid_schematic do
    sequence(:slug) { |n| "schematic-#{n}" }
    sequence(:name) { |n| "Schematic #{n}" }
    description { "A fabrication schematic" }
    association :output_definition, factory: :grid_item_definition
    output_quantity { 1 }
    xp_reward { 10 }
    required_clearance { 0 }
    published { true }
    position { 0 }

    trait :unpublished do
      published { false }
    end

    trait :clearance_gated do
      required_clearance { 5 }
    end
  end
end
