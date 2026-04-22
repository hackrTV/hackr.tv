# == Schema Information
#
# Table name: grid_item_definitions
# Database name: primary
#
#  id          :integer          not null, primary key
#  description :text
#  item_type   :string           not null
#  max_stack   :integer
#  name        :string           not null
#  properties  :json             not null
#  rarity      :string           not null
#  slug        :string           not null
#  value       :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_grid_item_definitions_on_item_type  (item_type)
#  index_grid_item_definitions_on_slug       (slug) UNIQUE
#
FactoryBot.define do
  factory :grid_item_definition do
    sequence(:slug) { |n| "item-def-#{n}" }
    sequence(:name) { |n| "Item Definition #{n}" }
    description { "A catalog item definition" }
    item_type { "tool" }
    rarity { "common" }
    value { 10 }
    properties { {} }

    trait :component do
      item_type { "rig_component" }
      properties { {"slot" => "gpu", "rate_multiplier" => 1.0} }
    end

    trait :consumable do
      item_type { "consumable" }
      properties { {"effect_type" => "heal", "amount" => 25} }
    end

    trait :fixture do
      sequence(:slug) { |n| "fixture-def-#{n}" }
      sequence(:name) { |n| "Storage Fixture #{n}" }
      item_type { "fixture" }
      max_stack { 1 }
      properties { {"storage_capacity" => 8, "fixture_type" => "data_rack"} }
    end

    trait :gear do
      sequence(:slug) { |n| "gear-def-#{n}" }
      sequence(:name) { |n| "Gear Item #{n}" }
      item_type { "gear" }
      max_stack { 1 }
      properties { {"slot" => "head", "effects" => {}} }
    end

    trait :rare do
      rarity { "rare" }
    end

    trait :unicorn do
      rarity { "unicorn" }
    end
  end
end
