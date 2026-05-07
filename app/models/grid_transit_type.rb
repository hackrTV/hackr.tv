# frozen_string_literal: true

class GridTransitType < ApplicationRecord
  has_paper_trail

  CATEGORIES = %w[public private slipstream].freeze

  has_many :grid_region_transit_assignments, dependent: :destroy
  has_many :grid_regions, through: :grid_region_transit_assignments
  has_many :grid_transit_routes, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  def to_param = slug
  validates :category, inclusion: {in: CATEGORIES}
  validates :base_fare, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :min_clearance, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:position, :name) }

  def public_route? = category == "public"
  def private_point? = category == "private"
  def slipstream? = category == "slipstream"
end
