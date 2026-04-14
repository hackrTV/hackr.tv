# == Schema Information
#
# Table name: grid_factions
# Database name: primary
#
#  id           :integer          not null, primary key
#  color_scheme :string
#  description  :text
#  kind         :string           default("collective"), not null
#  name         :string
#  position     :integer          default(0), not null
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer
#  parent_id    :integer
#
# Indexes
#
#  index_grid_factions_on_kind       (kind)
#  index_grid_factions_on_parent_id  (parent_id)
#  index_grid_factions_on_slug       (slug) UNIQUE
#
# Foreign Keys
#
#  parent_id  (parent_id => grid_factions.id)
#
FactoryBot.define do
  factory :grid_faction do
    sequence(:name) { |n| "Faction #{n}" }
    sequence(:slug) { |n| "faction_#{n}" }
    description { "A faction in THE PULSE GRID" }
    color_scheme { "purple" }
    kind { "collective" }
    position { 0 }
    artist_id { nil }
  end

  factory :grid_faction_rep_link do
    association :source_faction, factory: :grid_faction
    association :target_faction, factory: :grid_faction
    weight { 1.0 }
  end
end
