# == Schema Information
#
# Table name: grid_regions
# Database name: primary
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_grid_regions_on_slug  (slug) UNIQUE
#
FactoryBot.define do
  factory :grid_region do
    sequence(:name) { |n| "Region #{n}" }
    sequence(:slug) { |n| "region-#{n}" }
    description { "A test region in THE PULSE GRID" }
  end
end
