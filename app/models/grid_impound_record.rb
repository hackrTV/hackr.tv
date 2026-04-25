# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_impound_records
# Database name: primary
#
#  id                   :integer          not null, primary key
#  bribe_cost           :integer          default(0), not null
#  status               :string           default("impounded"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  grid_hackr_breach_id :integer
#  grid_hackr_id        :integer          not null
#
# Indexes
#
#  index_grid_impound_records_on_grid_hackr_breach_id      (grid_hackr_breach_id)
#  index_grid_impound_records_on_grid_hackr_id             (grid_hackr_id)
#  index_grid_impound_records_on_grid_hackr_id_and_status  (grid_hackr_id,status)
#
# Foreign Keys
#
#  grid_hackr_breach_id  (grid_hackr_breach_id => grid_hackr_breaches.id) ON DELETE => nullify
#  grid_hackr_id         (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#
class GridImpoundRecord < ApplicationRecord
  STATUSES = %w[impounded recovered forfeited].freeze

  has_paper_trail

  belongs_to :grid_hackr
  belongs_to :grid_hackr_breach, optional: true
  has_many :impounded_items,
    class_name: "GridItem",
    foreign_key: :grid_impound_record_id,
    dependent: :nullify

  validates :status, inclusion: {in: STATUSES}
  validates :bribe_cost, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :impounded, -> { where(status: "impounded") }
  scope :recovered, -> { where(status: "recovered") }
  scope :forfeited, -> { where(status: "forfeited") }
  scope :for_hackr, ->(hackr) { where(grid_hackr: hackr) }

  def impounded?
    status == "impounded"
  end

  def recovered?
    status == "recovered"
  end

  def forfeited?
    status == "forfeited"
  end
end
