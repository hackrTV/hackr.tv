# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_breach_templates
# Database name: primary
#
#  id                    :integer          not null, primary key
#  base_detection_rate   :integer          default(5), not null
#  cooldown_max          :integer          default(600), not null
#  cooldown_min          :integer          default(300), not null
#  cred_reward           :integer          default(0), not null
#  danger_level_min      :integer          default(0), not null
#  description           :text
#  min_clearance         :integer          default(0), not null
#  name                  :string           not null
#  pnr_threshold         :integer          default(75), not null
#  position              :integer          default(0), not null
#  protocol_composition  :json             not null
#  published             :boolean          default(FALSE), not null
#  requires_item_slug    :string
#  requires_mission_slug :string
#  reward_table          :json             not null
#  slug                  :string           not null
#  tier                  :string           default("standard"), not null
#  xp_reward             :integer          default(0), not null
#  zone_slugs            :json             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_grid_breach_templates_on_published  (published)
#  index_grid_breach_templates_on_slug       (slug) UNIQUE
#  index_grid_breach_templates_on_tier       (tier)
#
FactoryBot.define do
  factory :grid_breach_template do
    sequence(:slug) { |n| "breach-template-#{n}" }
    sequence(:name) { |n| "Breach Template #{n}" }
    description { "A test breach template." }
    tier { "standard" }
    min_clearance { 0 }
    pnr_threshold { 75 }
    base_detection_rate { 5 }
    cooldown_min { 300 }
    cooldown_max { 600 }
    xp_reward { 100 }
    cred_reward { 50 }
    published { true }
    position { 0 }
    protocol_composition do
      [
        {"type" => "trace", "count" => 1, "health" => 50, "max_health" => 50, "charge_rounds" => 0},
        {"type" => "feedback", "count" => 1, "health" => 60, "max_health" => 60, "charge_rounds" => 1}
      ]
    end
    reward_table { {} }

    trait :unpublished do
      published { false }
    end

    trait :ambient do
      tier { "ambient" }
      danger_level_min { 1 }
      zone_slugs { [] }
      cooldown_min { 0 }
      cooldown_max { 0 }
    end
  end
end
