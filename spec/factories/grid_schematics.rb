# == Schema Information
#
# Table name: grid_schematics
# Database name: primary
#
#  id                        :integer          not null, primary key
#  description               :text
#  name                      :string           not null
#  output_quantity           :integer          default(1), not null
#  position                  :integer          default(0), not null
#  published                 :boolean          default(FALSE), not null
#  required_achievement_slug :string
#  required_clearance        :integer          default(0), not null
#  required_mission_slug     :string
#  required_room_type        :string
#  slug                      :string           not null
#  xp_reward                 :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  output_definition_id      :integer          not null
#
# Indexes
#
#  index_grid_schematics_on_output_definition_id  (output_definition_id)
#  index_grid_schematics_on_slug                  (slug) UNIQUE
#
# Foreign Keys
#
#  output_definition_id  (output_definition_id => grid_item_definitions.id)
#
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

    trait :den_required do
      required_room_type { "den" }
    end
  end
end
