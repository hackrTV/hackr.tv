# frozen_string_literal: true

class GridSlipstreamRoute < ApplicationRecord
  has_paper_trail

  belongs_to :origin_region, class_name: "GridRegion"
  belongs_to :destination_region, class_name: "GridRegion"
  belongs_to :origin_room, class_name: "GridRoom"
  belongs_to :destination_room, class_name: "GridRoom"
  has_many :grid_slipstream_legs, -> { order(:position) }, dependent: :destroy
  has_many :grid_transit_journeys, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  def to_param = slug
  validates :min_clearance, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :base_heat_cost, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :detection_risk_base, numericality: {only_integer: true, in: 0..100}
  validate :regions_must_differ

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
  scope :accessible_by, ->(hackr) { active.where("min_clearance <= ?", hackr.stat("clearance")) }

  def leg_count = grid_slipstream_legs.size

  def legs_in_order = grid_slipstream_legs.order(:position).to_a

  def first_leg = grid_slipstream_legs.order(:position).first

  def next_leg_after(leg)
    grid_slipstream_legs.where("position > ?", leg.position).order(:position).first
  end

  private

  def regions_must_differ
    if origin_region_id.present? && origin_region_id == destination_region_id
      errors.add(:destination_region, "must differ from origin region")
    end
  end
end
