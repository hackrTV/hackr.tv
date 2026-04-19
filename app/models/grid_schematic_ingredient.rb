# frozen_string_literal: true

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
class GridSchematicIngredient < ApplicationRecord
  has_paper_trail

  belongs_to :grid_schematic
  belongs_to :input_definition, class_name: "GridItemDefinition"

  validates :quantity, numericality: {only_integer: true, greater_than: 0}
  validates :input_definition_id, uniqueness: {
    scope: :grid_schematic_id,
    message: "already configured as an ingredient for this schematic"
  }
  validate :input_and_output_differ

  scope :ordered, -> { order(:position, :id) }

  private

  def input_and_output_differ
    return unless grid_schematic&.output_definition_id
    if input_definition_id == grid_schematic.output_definition_id
      errors.add(:input_definition_id, "cannot be the same as the output")
    end
  end
end
