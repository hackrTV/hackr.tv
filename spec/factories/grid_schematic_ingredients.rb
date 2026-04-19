FactoryBot.define do
  factory :grid_schematic_ingredient do
    association :grid_schematic
    association :input_definition, factory: :grid_item_definition
    quantity { 1 }
    position { 0 }
  end
end
