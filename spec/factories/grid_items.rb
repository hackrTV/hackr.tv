# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id            :integer          not null, primary key
#  description   :text
#  item_type     :string
#  name          :string
#  properties    :json
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer
#  room_id       :integer
#
FactoryBot.define do
  factory :grid_item do
    name { "MyString" }
    description { "MyText" }
    item_type { "MyString" }
    room_id { 1 }
    grid_player_id { 1 }
    properties { "" }
  end
end
