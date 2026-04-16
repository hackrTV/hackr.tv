# == Schema Information
#
# Table name: grid_mission_arcs
# Database name: primary
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  position    :integer          default(0), not null
#  published   :boolean          default(FALSE), not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_grid_mission_arcs_on_slug  (slug) UNIQUE
#
FactoryBot.define do
  factory :grid_mission_arc do
    sequence(:slug) { |n| "test-arc-#{n}" }
    sequence(:name) { |n| "Test Arc #{n}" }
    description { "An arc for tests." }
    position { 1 }
    published { true }
  end
end
