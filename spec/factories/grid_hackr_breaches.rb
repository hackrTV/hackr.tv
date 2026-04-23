# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_hackr_breaches
# Database name: primary
#
#  id                      :integer          not null, primary key
#  actions_remaining       :integer          default(1), not null
#  actions_this_round      :integer          default(1), not null
#  detection_level         :integer          default(0), not null
#  ended_at                :datetime
#  inspiration             :integer          default(0), not null
#  pnr_threshold           :integer          default(75), not null
#  reward_multiplier       :decimal(5, 4)    default(1.0), not null
#  round_number            :integer          default(1), not null
#  started_at              :datetime         not null
#  state                   :string           default("active"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  grid_breach_template_id :integer          not null
#  grid_hackr_id           :integer          not null
#  origin_room_id          :integer
#
# Indexes
#
#  index_grid_hackr_breaches_on_grid_breach_template_id  (grid_breach_template_id)
#  index_grid_hackr_breaches_on_grid_hackr_id            (grid_hackr_id)
#  index_grid_hackr_breaches_on_state                    (state)
#  index_hackr_breaches_one_active_per_hackr             (grid_hackr_id) UNIQUE WHERE state = 'active'
#
# Foreign Keys
#
#  grid_breach_template_id  (grid_breach_template_id => grid_breach_templates.id) ON DELETE => restrict
#  grid_hackr_id            (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#  origin_room_id           (origin_room_id => grid_rooms.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :grid_hackr_breach do
    association :grid_hackr
    association :grid_breach_template
    origin_room_id { grid_hackr.current_room_id || create(:grid_room).id }
    state { "active" }
    detection_level { 0 }
    pnr_threshold { 75 }
    round_number { 1 }
    inspiration { 0 }
    actions_this_round { 1 }
    actions_remaining { 1 }
    reward_multiplier { 1.0 }
    started_at { Time.current }

    trait :completed do
      state { "success" }
      ended_at { Time.current }
    end
  end
end
