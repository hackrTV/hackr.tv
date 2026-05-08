# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_transit_routes
# Database name: primary
#
#  id                   :integer          not null, primary key
#  active               :boolean          default(TRUE), not null
#  description          :text
#  loop_route           :boolean          default(FALSE), not null
#  name                 :string           not null
#  position             :integer          default(0), not null
#  slug                 :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  grid_region_id       :integer          not null
#  grid_transit_type_id :integer          not null
#
# Indexes
#
#  index_grid_transit_routes_on_active                (active)
#  index_grid_transit_routes_on_grid_region_id        (grid_region_id)
#  index_grid_transit_routes_on_grid_transit_type_id  (grid_transit_type_id)
#  index_grid_transit_routes_on_slug                  (slug) UNIQUE
#
# Foreign Keys
#
#  grid_region_id        (grid_region_id => grid_regions.id) ON DELETE => restrict
#  grid_transit_type_id  (grid_transit_type_id => grid_transit_types.id) ON DELETE => restrict
#
class GridTransitRoute < ApplicationRecord
  has_paper_trail

  belongs_to :grid_transit_type
  belongs_to :grid_region
  has_many :grid_transit_stops, -> { order(:position) }, dependent: :destroy
  has_many :grid_transit_journeys, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  def to_param = slug

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
  scope :for_region, ->(region) { where(grid_region: region) }

  def stop_count = grid_transit_stops.size

  def stop_at_position(pos)
    grid_transit_stops.find_by(position: pos)
  end

  def stop_for_room(room)
    grid_transit_stops.find_by(grid_room_id: room.id)
  end

  def next_stop_after(stop)
    stops = grid_transit_stops.order(:position).to_a
    idx = stops.index { |s| s.id == stop.id }
    return nil if idx.nil?
    if idx + 1 < stops.size
      stops[idx + 1]
    elsif loop_route
      stops.first
    end
  end
end
