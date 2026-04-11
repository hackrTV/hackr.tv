# == Schema Information
#
# Table name: grid_mobs
# Database name: primary
#
#  id              :integer          not null, primary key
#  description     :text
#  dialogue_tree   :json
#  mob_type        :string
#  name            :string
#  vendor_config   :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_faction_id :integer
#  grid_room_id    :integer
#
FactoryBot.define do
  factory :grid_mob do
    sequence(:name) { |n| "Mob #{n}" }
    description { "A mobile entity in THE PULSE GRID" }
    association :grid_room
    mob_type { "lore" }
    dialogue_tree { {} }
    grid_faction { nil }

    trait :quest_giver do
      mob_type { "quest_giver" }
      dialogue_tree { {greeting: "I have a task for you..."} }
    end

    trait :vendor do
      mob_type { "vendor" }
      dialogue_tree { {greeting: "What are you buying?"} }
    end

    trait :special do
      mob_type { "special" }
    end
  end
end
