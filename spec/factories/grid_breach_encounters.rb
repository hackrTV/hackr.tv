# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_breach_encounters
# Database name: primary
#
#  id                      :integer          not null, primary key
#  cooldown_until          :datetime
#  instance_seed           :integer
#  state                   :string           default("available"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  grid_breach_template_id :integer          not null
#  grid_room_id            :integer          not null
#
# Indexes
#
#  index_breach_encounters_on_room_and_template             (grid_room_id,grid_breach_template_id)
#  index_grid_breach_encounters_on_grid_breach_template_id  (grid_breach_template_id)
#  index_grid_breach_encounters_on_grid_room_id             (grid_room_id)
#  index_grid_breach_encounters_on_state                    (state)
#
# Foreign Keys
#
#  grid_breach_template_id  (grid_breach_template_id => grid_breach_templates.id) ON DELETE => restrict
#  grid_room_id             (grid_room_id => grid_rooms.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :grid_breach_encounter do
    association :grid_breach_template
    association :grid_room
    state { "available" }
  end
end
