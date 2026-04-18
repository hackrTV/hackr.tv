# frozen_string_literal: true

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
class GridSalvageYield < ApplicationRecord
  belongs_to :source_definition, class_name: "GridItemDefinition"
  belongs_to :output_definition, class_name: "GridItemDefinition"

  validates :quantity, numericality: {only_integer: true, greater_than: 0}
  validates :output_definition_id, uniqueness: {
    scope: :source_definition_id,
    message: "already configured as a yield for this item"
  }
  validate :source_and_output_differ

  scope :ordered, -> { order(:position, :id) }

  private

  def source_and_output_differ
    if source_definition_id == output_definition_id
      errors.add(:output_definition_id, "cannot be the same as the source")
    end
  end
end
