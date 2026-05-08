# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_transit_journeys
# Database name: primary
#
#  id                       :integer          not null, primary key
#  breach_mid_journey       :boolean          default(FALSE), not null
#  ended_at                 :datetime
#  fare_paid                :integer          default(0), not null
#  heat_accumulated         :integer          default(0), not null
#  journey_type             :string           not null
#  legs_completed           :integer          default(0), not null
#  meta                     :json             not null
#  pending_fork             :boolean          default(FALSE), not null
#  started_at               :datetime         not null
#  state                    :string           default("active"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  current_leg_id           :integer
#  current_stop_id          :integer
#  destination_room_id      :integer
#  grid_hackr_id            :integer          not null
#  grid_slipstream_route_id :integer
#  grid_transit_route_id    :integer
#  origin_room_id           :integer
#
# Indexes
#
#  index_grid_transit_journeys_on_current_leg_id            (current_leg_id)
#  index_grid_transit_journeys_on_current_stop_id           (current_stop_id)
#  index_grid_transit_journeys_on_destination_room_id       (destination_room_id)
#  index_grid_transit_journeys_on_grid_hackr_id             (grid_hackr_id)
#  index_grid_transit_journeys_on_grid_slipstream_route_id  (grid_slipstream_route_id)
#  index_grid_transit_journeys_on_grid_transit_route_id     (grid_transit_route_id)
#  index_grid_transit_journeys_on_origin_room_id            (origin_room_id)
#  index_grid_transit_journeys_on_state                     (state)
#  index_transit_journeys_one_active_per_hackr              (grid_hackr_id) UNIQUE WHERE state = 'active'
#
# Foreign Keys
#
#  current_leg_id            (current_leg_id => grid_slipstream_legs.id) ON DELETE => nullify
#  current_stop_id           (current_stop_id => grid_transit_stops.id) ON DELETE => nullify
#  destination_room_id       (destination_room_id => grid_rooms.id) ON DELETE => nullify
#  grid_hackr_id             (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#  grid_slipstream_route_id  (grid_slipstream_route_id => grid_slipstream_routes.id) ON DELETE => nullify
#  grid_transit_route_id     (grid_transit_route_id => grid_transit_routes.id) ON DELETE => nullify
#  origin_room_id            (origin_room_id => grid_rooms.id) ON DELETE => nullify
#
class GridTransitJourney < ApplicationRecord
  JOURNEY_TYPES = %w[slipstream local_public local_private].freeze
  STATES = %w[active completed abandoned ejected].freeze

  belongs_to :grid_hackr
  belongs_to :origin_room, class_name: "GridRoom", optional: true
  belongs_to :destination_room, class_name: "GridRoom", optional: true

  # Slipstream associations
  belongs_to :grid_slipstream_route, optional: true
  belongs_to :current_leg, class_name: "GridSlipstreamLeg", optional: true

  # Local transit associations
  belongs_to :grid_transit_route, optional: true
  belongs_to :current_stop, class_name: "GridTransitStop", optional: true

  validates :journey_type, inclusion: {in: JOURNEY_TYPES}
  validates :state, inclusion: {in: STATES}

  scope :active, -> { where(state: "active") }

  def active? = state == "active"
  def slipstream? = journey_type == "slipstream"
  def local_public? = journey_type == "local_public"
  def local_private? = journey_type == "local_private"
  def local? = local_public? || local_private?
  def awaiting_fork? = pending_fork?

  def total_legs
    grid_slipstream_route&.leg_count || 0
  end

  def chosen_forks
    meta&.dig("chosen_forks") || {}
  end
end
