# frozen_string_literal: true

class GridRegionTransitAssignment < ApplicationRecord
  belongs_to :grid_region
  belongs_to :grid_transit_type

  validates :grid_region_id, uniqueness: {scope: :grid_transit_type_id}
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}
end
