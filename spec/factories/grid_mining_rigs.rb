FactoryBot.define do
  factory :grid_mining_rig do
    association :grid_hackr
    active { false }
  end
end
