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
require "rails_helper"

RSpec.describe GridExit, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
