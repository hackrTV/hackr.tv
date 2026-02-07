# == Schema Information
#
# Table name: feature_grants
# Database name: primary
#
#  id            :integer          not null, primary key
#  feature       :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_feature_grants_on_feature                    (feature)
#  index_feature_grants_on_grid_hackr_id              (grid_hackr_id)
#  index_feature_grants_on_grid_hackr_id_and_feature  (grid_hackr_id,feature) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class FeatureGrant < ApplicationRecord
  PULSE_GRID = "pulse_grid"

  belongs_to :grid_hackr

  validates :feature, presence: true, uniqueness: {scope: :grid_hackr_id}
end
