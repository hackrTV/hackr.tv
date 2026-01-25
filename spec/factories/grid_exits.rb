# == Schema Information
#
# Table name: grid_exits
# Database name: primary
#
#  id               :integer          not null, primary key
#  direction        :string
#  locked           :boolean
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  from_room_id     :integer
#  requires_item_id :integer
#  to_room_id       :integer
#
# Indexes
#
#  index_grid_exits_on_from_room_id  (from_room_id)
#  index_grid_exits_on_to_room_id    (to_room_id)
#
FactoryBot.define do
  factory :grid_exit do
    from_room_id { 1 }
    to_room_id { 1 }
    direction { "MyString" }
    locked { false }
    requires_item_id { 1 }
  end
end
