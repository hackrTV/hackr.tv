# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_transit_types
# Database name: primary
#
#  id            :integer          not null, primary key
#  base_fare     :integer          default(0), not null
#  category      :string           not null
#  description   :text
#  icon_key      :string
#  min_clearance :integer          default(0), not null
#  name          :string           not null
#  position      :integer          default(0), not null
#  published     :boolean          default(FALSE), not null
#  slug          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_grid_transit_types_on_category  (category)
#  index_grid_transit_types_on_slug      (slug) UNIQUE
#
class GridTransitType < ApplicationRecord
  has_paper_trail

  CATEGORIES = %w[public private slipstream].freeze

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
