# frozen_string_literal: true

module DataAudit
  module Checks
    class SchematicNoIngredients < DataAudit::Check
      SEVERITY = "warning"
      DOMAIN = "grid"

      def violations
        GridSchematic
          .where(published: true)
          .left_joins(:ingredients)
          .group("grid_schematics.id")
          .having("COUNT(grid_schematic_ingredients.id) = 0")
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Published schematic '#{name}' has no ingredients",
              subject_type: "GridSchematic",
              subject_id: id
            )
          end
      end
    end
  end
end
