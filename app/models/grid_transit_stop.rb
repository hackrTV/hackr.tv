# frozen_string_literal: true

class GridTransitStop < ApplicationRecord
  belongs_to :grid_transit_route
  belongs_to :grid_room

  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0},
    uniqueness: {scope: :grid_transit_route_id}

  def display_name
    label.presence || grid_room.name
  end
end
