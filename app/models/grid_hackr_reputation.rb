# == Schema Information
#
# Table name: grid_hackr_reputations
# Database name: primary
#
#  id            :integer          not null, primary key
#  subject_type  :string           not null
#  value         :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  subject_id    :bigint           not null
#
# Indexes
#
#  index_grid_hackr_reputations_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_reputations_on_subject             (subject_type,subject_id)
#  index_hackr_reputations_unique                 (grid_hackr_id,subject_type,subject_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class GridHackrReputation < ApplicationRecord
  MIN_VALUE = -1000
  MAX_VALUE = 1000

  belongs_to :grid_hackr
  belongs_to :subject, polymorphic: true

  validates :subject_type, presence: true
  validates :subject_id, presence: true
  validates :value,
    numericality: {only_integer: true, greater_than_or_equal_to: MIN_VALUE, less_than_or_equal_to: MAX_VALUE}
  validates :grid_hackr_id, uniqueness: {scope: [:subject_type, :subject_id]}

  scope :for_subject_type, ->(type) { where(subject_type: type.to_s) }
  scope :nonzero, -> { where.not(value: 0) }
end
