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
FactoryBot.define do
  factory :feature_grant do
    association :grid_hackr
    feature { FeatureGrant::PULSE_GRID }
  end
end
