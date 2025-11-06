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
