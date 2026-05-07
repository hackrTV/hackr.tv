# frozen_string_literal: true

class GridSlipstreamLeg < ApplicationRecord
  belongs_to :grid_slipstream_route

  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 1},
    uniqueness: {scope: :grid_slipstream_route_id}
  validates :name, presence: true

  def option_keys = (fork_options || []).map { |o| o["key"] }

  def option_for(key) = (fork_options || []).find { |o| o["key"] == key }

  def has_forks? = fork_options.present? && fork_options.any?
end
