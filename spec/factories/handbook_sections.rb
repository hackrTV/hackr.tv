# == Schema Information
#
# Table name: handbook_sections
# Database name: primary
#
#  id         :integer          not null, primary key
#  icon       :string
#  name       :string           not null
#  position   :integer          default(0), not null
#  published  :boolean          default(TRUE), not null
#  slug       :string           not null
#  summary    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_handbook_sections_on_published               (published)
#  index_handbook_sections_on_published_and_position  (published,position)
#  index_handbook_sections_on_slug                    (slug) UNIQUE
#
FactoryBot.define do
  factory :handbook_section do
    sequence(:name) { |n| "Section #{n}" }
    sequence(:slug) { |n| "section-#{n}" }
    icon { ">>" }
    summary { "Section summary" }
    position { 0 }
    published { true }

    trait :unpublished do
      published { false }
    end
  end
end
