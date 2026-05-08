# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_slipstream_legs
# Database name: primary
#
#  id                       :integer          not null, primary key
#  breach_template_slug     :string
#  description              :text
#  fork_options             :json             not null
#  name                     :string           not null
#  position                 :integer          not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  grid_slipstream_route_id :integer          not null
#
# Indexes
#
#  index_grid_slipstream_legs_on_grid_slipstream_route_id  (grid_slipstream_route_id)
#  index_slipstream_legs_route_position                    (grid_slipstream_route_id,position) UNIQUE
#
# Foreign Keys
#
#  grid_slipstream_route_id  (grid_slipstream_route_id => grid_slipstream_routes.id) ON DELETE => cascade
#
class GridSlipstreamLeg < ApplicationRecord
  belongs_to :grid_slipstream_route

  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 1},
    uniqueness: {scope: :grid_slipstream_route_id}
  validates :name, presence: true

  def option_keys = (fork_options || []).map { |o| o["key"] }

  def option_for(key) = (fork_options || []).find { |o| o["key"] == key }

  def has_forks? = fork_options.present? && fork_options.any?
end
