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
FactoryBot.define do
  factory :grid_impound_record do
    association :grid_hackr
    status { "impounded" }
    bribe_cost { 500 }

    trait :recovered do
      status { "recovered" }
    end

    trait :forfeited do
      status { "forfeited" }
    end

    trait :with_breach do
      association :grid_hackr_breach
    end
  end
end
