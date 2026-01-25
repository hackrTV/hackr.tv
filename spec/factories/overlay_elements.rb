# == Schema Information
#
# Table name: overlay_elements
# Database name: primary
#
#  id           :integer          not null, primary key
#  active       :boolean          default(TRUE)
#  element_type :string           not null
#  name         :string           not null
#  settings     :json
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_overlay_elements_on_active        (active)
#  index_overlay_elements_on_element_type  (element_type)
#  index_overlay_elements_on_slug          (slug) UNIQUE
#
FactoryBot.define do
  factory :overlay_element do
    sequence(:name) { |n| "Element #{n}" }
    sequence(:slug) { |n| "element-#{n}" }
    element_type { "now_playing" }
    active { true }
    settings { {} }

    trait :inactive do
      active { false }
    end

    trait :pulsewire_feed do
      element_type { "pulsewire_feed" }
    end

    trait :grid_activity do
      element_type { "grid_activity" }
    end

    trait :alert do
      element_type { "alert" }
    end

    trait :lower_third do
      element_type { "lower_third" }
    end

    trait :codex_entry do
      element_type { "codex_entry" }
    end

    trait :ticker_top do
      element_type { "ticker_top" }
    end

    trait :ticker_bottom do
      element_type { "ticker_bottom" }
    end
  end
end
