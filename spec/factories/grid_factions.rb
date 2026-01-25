# == Schema Information
#
# Table name: grid_factions
# Database name: primary
#
#  id           :integer          not null, primary key
#  color_scheme :string
#  description  :text
#  name         :string
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer
#
FactoryBot.define do
  factory :grid_faction do
    name { "MyString" }
    slug { "MyString" }
    description { "MyText" }
    color_scheme { "MyString" }
    artist_id { 1 }
  end
end
