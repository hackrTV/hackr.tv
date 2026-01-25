# == Schema Information
#
# Table name: overlay_lower_thirds
# Database name: primary
#
#  id             :integer          not null, primary key
#  active         :boolean          default(TRUE)
#  logo_url       :string
#  name           :string           not null
#  primary_text   :string           not null
#  secondary_text :string
#  slug           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_overlay_lower_thirds_on_active  (active)
#  index_overlay_lower_thirds_on_slug    (slug) UNIQUE
#
FactoryBot.define do
  factory :overlay_lower_third do
    sequence(:name) { |n| "Lower Third #{n}" }
    sequence(:slug) { |n| "lower-third-#{n}" }
    primary_text { "Primary Text" }
    secondary_text { "Secondary Text" }
    logo_url { nil }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_logo do
      logo_url { "https://example.com/logo.png" }
    end
  end
end
