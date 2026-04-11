# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id                 :integer          not null, primary key
#  description        :text
#  item_type          :string
#  name               :string
#  properties         :json
#  quantity           :integer          default(1), not null
#  rarity             :string
#  value              :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  grid_hackr_id      :integer
#  grid_mining_rig_id :integer
#  room_id            :integer
#
# Indexes
#
#  index_grid_items_on_grid_mining_rig_id  (grid_mining_rig_id)
#
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
