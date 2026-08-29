FactoryBot.define do
  factory :feature_grant do
    association :grid_hackr
    feature { FeatureGrant::PULSE_GRID }
  end
end
