# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_transit_stops
# Database name: primary
#
#  id                    :integer          not null, primary key
#  is_terminus           :boolean          default(FALSE), not null
#  label                 :string
#  position              :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  grid_room_id          :integer          not null
#  grid_transit_route_id :integer          not null
#
# Indexes
#
#  index_grid_transit_stops_on_grid_room_id           (grid_room_id)
#  index_grid_transit_stops_on_grid_transit_route_id  (grid_transit_route_id)
#  index_transit_stops_route_position                 (grid_transit_route_id,position) UNIQUE
#
# Foreign Keys
#
#  grid_room_id           (grid_room_id => grid_rooms.id) ON DELETE => restrict
#  grid_transit_route_id  (grid_transit_route_id => grid_transit_routes.id) ON DELETE => cascade
#
class GridTransitStop < ApplicationRecord
  belongs_to :grid_transit_route
  belongs_to :grid_room

  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0},
    uniqueness: {scope: :grid_transit_route_id}

  def display_name
    label.presence || grid_room.name
  end
end
