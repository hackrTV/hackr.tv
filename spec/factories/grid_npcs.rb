FactoryBot.define do
  factory :grid_npc do
    name { "MyString" }
    description { "MyText" }
    grid_room_id { 1 }
    npc_type { "MyString" }
    dialogue_tree { "" }
    grid_faction_id { 1 }
  end
end
