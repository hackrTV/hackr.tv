# == Schema Information
#
# Table name: grid_missions
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  dialogue_path       :json
#  min_clearance       :integer          default(0), not null
#  min_rep_value       :integer          default(0), not null
#  name                :string           not null
#  position            :integer          default(0), not null
#  published           :boolean          default(FALSE), not null
#  repeatable          :boolean          default(FALSE), not null
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  giver_mob_id        :integer
#  grid_mission_arc_id :integer
#  min_rep_faction_id  :integer
#  prereq_mission_id   :integer
#
# Indexes
#
#  index_grid_missions_on_giver_mob_id         (giver_mob_id)
#  index_grid_missions_on_grid_mission_arc_id  (grid_mission_arc_id)
#  index_grid_missions_on_min_rep_faction_id   (min_rep_faction_id)
#  index_grid_missions_on_prereq_mission_id    (prereq_mission_id)
#  index_grid_missions_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  giver_mob_id         (giver_mob_id => grid_mobs.id) ON DELETE => nullify
#  grid_mission_arc_id  (grid_mission_arc_id => grid_mission_arcs.id) ON DELETE => nullify
#  min_rep_faction_id   (min_rep_faction_id => grid_factions.id) ON DELETE => nullify
#  prereq_mission_id    (prereq_mission_id => grid_missions.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :grid_mission do
    sequence(:slug) { |n| "test-mission-#{n}" }
    sequence(:name) { |n| "Test Mission #{n}" }
    description { "A test mission." }
    association :giver_mob, factory: %i[grid_mob quest_giver]
    grid_mission_arc { nil }
    prereq_mission { nil }
    min_clearance { 0 }
    min_rep_faction { nil }
    min_rep_value { 0 }
    repeatable { false }
    position { 1 }
    published { true }

    trait :repeatable do
      repeatable { true }
    end

    trait :unpublished do
      published { false }
    end
  end
end
