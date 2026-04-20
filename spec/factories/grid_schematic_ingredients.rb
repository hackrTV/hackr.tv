# == Schema Information
#
# Table name: grid_schematic_ingredients
# Database name: primary
#
#  id                  :integer          not null, primary key
#  position            :integer          default(0), not null
#  quantity            :integer          default(1), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  grid_schematic_id   :integer          not null
#  input_definition_id :integer          not null
#
# Indexes
#
#  index_grid_schematic_ingredients_on_grid_schematic_id    (grid_schematic_id)
#  index_grid_schematic_ingredients_on_input_definition_id  (input_definition_id)
#  index_grid_schematic_ingredients_unique                  (grid_schematic_id,input_definition_id) UNIQUE
#
# Foreign Keys
#
#  grid_schematic_id    (grid_schematic_id => grid_schematics.id)
#  input_definition_id  (input_definition_id => grid_item_definitions.id)
#
FactoryBot.define do
  factory :grid_schematic_ingredient do
    association :grid_schematic
    association :input_definition, factory: :grid_item_definition
    quantity { 1 }
    position { 0 }
  end
end
