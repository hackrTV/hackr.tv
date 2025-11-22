FactoryBot.define do
  factory :echo do
    association :pulse
    association :grid_hackr
    # echoed_at is auto-set by the model
  end
end
