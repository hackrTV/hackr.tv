# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id                 :integer          not null, primary key
#  description        :text
#  item_type          :string
#  name               :string
#  properties         :json
#  quantity           :integer          default(1), not null
#  rarity             :string
#  value              :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  grid_hackr_id      :integer
#  grid_mining_rig_id :integer
#  room_id            :integer
#
# Indexes
#
#  index_grid_items_on_grid_mining_rig_id  (grid_mining_rig_id)
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
