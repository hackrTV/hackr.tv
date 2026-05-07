# frozen_string_literal: true

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
