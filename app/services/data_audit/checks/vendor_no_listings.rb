# frozen_string_literal: true

module DataAudit
  module Checks
    class VendorNoListings < DataAudit::Check
      SEVERITY = "warning"
      DOMAIN = "grid"

      def violations
        GridMob
          .where(mob_type: "vendor")
          .left_joins(:grid_shop_listings)
          .group("grid_mobs.id")
          .having("COUNT(grid_shop_listings.id) = 0")
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Vendor mob '#{name}' has no shop listings",
              subject_type: "GridMob",
              subject_id: id
            )
          end
      end
    end
  end
end
