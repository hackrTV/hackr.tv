# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_slipstream_routes
# Database name: primary
#
#  id                    :integer          not null, primary key
#  active                :boolean          default(TRUE), not null
#  base_heat_cost        :integer          default(10), not null
#  description           :text
#  detection_risk_base   :integer          default(15), not null
#  min_clearance         :integer          default(15), not null
#  name                  :string           not null
#  position              :integer          default(0), not null
#  slug                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  destination_region_id :integer          not null
#  destination_room_id   :integer          not null
#  origin_region_id      :integer          not null
#  origin_room_id        :integer          not null
#
# Indexes
#
#  index_grid_slipstream_routes_on_destination_region_id  (destination_region_id)
#  index_grid_slipstream_routes_on_destination_room_id    (destination_room_id)
#  index_grid_slipstream_routes_on_origin_region_id       (origin_region_id)
#  index_grid_slipstream_routes_on_origin_room_id         (origin_room_id)
#  index_grid_slipstream_routes_on_slug                   (slug) UNIQUE
#  index_slipstream_routes_origin_dest                    (origin_region_id,destination_region_id) UNIQUE
#
# Foreign Keys
#
#  destination_region_id  (destination_region_id => grid_regions.id) ON DELETE => restrict
#  destination_room_id    (destination_room_id => grid_rooms.id) ON DELETE => restrict
#  origin_region_id       (origin_region_id => grid_regions.id) ON DELETE => restrict
#  origin_room_id         (origin_room_id => grid_rooms.id) ON DELETE => restrict
#
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
