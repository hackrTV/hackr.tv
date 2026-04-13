# == Schema Information
#
# Table name: handbook_articles
# Database name: primary
#
#  id                  :integer          not null, primary key
#  body                :text
#  difficulty          :string
#  kind                :string           default("reference"), not null
#  metadata            :json
#  position            :integer          default(0), not null
#  published           :boolean          default(TRUE), not null
#  slug                :string           not null
#  summary             :text
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  handbook_section_id :integer          not null
#
# Indexes
#
#  index_handbook_articles_on_handbook_section_id               (handbook_section_id)
#  index_handbook_articles_on_handbook_section_id_and_position  (handbook_section_id,position)
#  index_handbook_articles_on_kind                              (kind)
#  index_handbook_articles_on_published                         (published)
#  index_handbook_articles_on_slug                              (slug) UNIQUE
#
# Foreign Keys
#
#  handbook_section_id  (handbook_section_id => handbook_sections.id)
#
FactoryBot.define do
  factory :handbook_article do
    handbook_section
    sequence(:title) { |n| "Article #{n}" }
    sequence(:slug) { |n| "article-#{n}" }
    kind { "reference" }
    summary { "Article summary" }
    body { "# Article body\n\nMarkdown content." }
    position { 0 }
    published { true }
    metadata { {} }

    trait :tutorial do
      kind { "tutorial" }
      difficulty { "beginner" }
    end

    trait :unpublished do
      published { false }
    end
  end
end
