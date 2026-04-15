# == Schema Information
#
# Table name: grid_achievements
# Database name: primary
#
#  id           :integer          not null, primary key
#  badge_icon   :string
#  category     :string           default("grid"), not null
#  cred_reward  :integer          default(0), not null
#  description  :text
#  hidden       :boolean          default(FALSE), not null
#  name         :string           not null
#  slug         :string           not null
#  trigger_data :json
#  trigger_type :string           not null
#  xp_reward    :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_grid_achievements_on_category      (category)
#  index_grid_achievements_on_slug          (slug) UNIQUE
#  index_grid_achievements_on_trigger_type  (trigger_type)
#
FactoryBot.define do
  factory :grid_achievement do
    sequence(:slug) { |n| "test-achievement-#{n}" }
    sequence(:name) { |n| "Test Achievement #{n}" }
    description { "A test achievement." }
    badge_icon { "*" }
    trigger_type { "rooms_visited" }
    trigger_data { {"count" => 1} }
    xp_reward { 10 }
    cred_reward { 0 }
    category { "grid" }
    hidden { false }

    trait :manual do
      trigger_type { "manual" }
      trigger_data { {} }
    end

    trait :with_cred do
      cred_reward { 10 }
    end
  end
end
