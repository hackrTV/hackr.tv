FactoryBot.define do
  factory :grid_exit do
    from_room_id { 1 }
    to_room_id { 1 }
    direction { "MyString" }
    locked { false }
    requires_item_id { 1 }
  end
end
