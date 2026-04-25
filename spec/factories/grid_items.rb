# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id                      :integer          not null, primary key
#  description             :text
#  equipped_slot           :string
#  item_type               :string
#  name                    :string
#  properties              :json
#  quantity                :integer          default(1), not null
#  rarity                  :string
#  value                   :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  container_id            :integer
#  deck_id                 :integer
#  grid_hackr_id           :integer
#  grid_impound_record_id  :integer
#  grid_item_definition_id :integer          not null
#  grid_mining_rig_id      :integer
#  room_id                 :integer
#
# Indexes
#
#  index_grid_items_on_container_id                (container_id)
#  index_grid_items_on_deck_id                     (deck_id)
#  index_grid_items_on_grid_hackr_id               (grid_hackr_id)
#  index_grid_items_on_grid_impound_record_id      (grid_impound_record_id)
#  index_grid_items_on_grid_item_definition_id     (grid_item_definition_id)
#  index_grid_items_on_grid_mining_rig_id          (grid_mining_rig_id)
#  index_grid_items_on_hackr_equipped_slot_unique  (grid_hackr_id,equipped_slot) UNIQUE WHERE equipped_slot IS NOT NULL
#
# Foreign Keys
#
#  container_id             (container_id => grid_items.id)
#  deck_id                  (deck_id => grid_items.id) ON DELETE => nullify
#  grid_impound_record_id   (grid_impound_record_id => grid_impound_records.id) ON DELETE => nullify
#  grid_item_definition_id  (grid_item_definition_id => grid_item_definitions.id)
#
FactoryBot.define do
  factory :grid_item do
    association :grid_item_definition

    # Denormalized fields derived from the definition to stay in sync.
    # Explicit overrides (e.g. `create(:grid_item, name: "Custom")`) still work.
    name { grid_item_definition.name }
    description { grid_item_definition.description }
    item_type { grid_item_definition.item_type }
    rarity { grid_item_definition.rarity }
    value { grid_item_definition.value }
    properties { grid_item_definition.properties&.deep_dup || {} }
    quantity { 1 }

    # By default, items are in a room
    association :room, factory: :grid_room

    trait :in_inventory do
      room { nil }
      association :grid_hackr
    end

    trait :component do
      association :grid_item_definition, factory: [:grid_item_definition, :component]
    end

    trait :consumable do
      association :grid_item_definition, factory: [:grid_item_definition, :consumable]
    end

    trait :fixture do
      association :grid_item_definition, factory: [:grid_item_definition, :fixture]
    end

    trait :placed_fixture do
      fixture
      grid_hackr { nil }
      # room must be set by caller (the den room)
    end
  end
end
