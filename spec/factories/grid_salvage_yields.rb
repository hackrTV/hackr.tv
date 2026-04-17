# == Schema Information
#
# Table name: grid_salvage_yields
# Database name: primary
#
#  id                   :integer          not null, primary key
#  position             :integer          default(0), not null
#  quantity             :integer          default(1), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  output_definition_id :integer          not null
#  source_definition_id :integer          not null
#
# Indexes
#
#  index_grid_salvage_yields_on_output_definition_id  (output_definition_id)
#  index_grid_salvage_yields_on_source_definition_id  (source_definition_id)
#  index_grid_salvage_yields_unique                   (source_definition_id,output_definition_id) UNIQUE
#
# Foreign Keys
#
#  output_definition_id  (output_definition_id => grid_item_definitions.id)
#  source_definition_id  (source_definition_id => grid_item_definitions.id)
#
FactoryBot.define do
  factory :grid_salvage_yield do
    association :source_definition, factory: :grid_item_definition
    association :output_definition, factory: :grid_item_definition
    quantity { 1 }
    position { 0 }
  end
end
