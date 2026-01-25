# == Schema Information
#
# Table name: user_punishments
# Database name: primary
#
#  id              :integer          not null, primary key
#  expires_at      :datetime
#  punishment_type :string           not null
#  reason          :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer          not null
#  issued_by_id    :integer          not null
#
# Indexes
#
#  index_user_punishments_on_expires_at                         (expires_at)
#  index_user_punishments_on_grid_hackr_id                      (grid_hackr_id)
#  index_user_punishments_on_grid_hackr_id_and_punishment_type  (grid_hackr_id,punishment_type)
#  index_user_punishments_on_issued_by_id                       (issued_by_id)
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  issued_by_id   (issued_by_id => grid_hackrs.id)
#
FactoryBot.define do
  factory :user_punishment do
    association :grid_hackr
    association :issued_by, factory: :grid_hackr
    punishment_type { "squelch" }
    reason { "Test punishment" }
    expires_at { nil }

    trait :squelch do
      punishment_type { "squelch" }
    end

    trait :blackout do
      punishment_type { "blackout" }
    end

    trait :temporary do
      expires_at { 30.minutes.from_now }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end
  end
end
