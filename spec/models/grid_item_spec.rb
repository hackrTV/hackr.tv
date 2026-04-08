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
#  quantity      :integer          default(1), not null
#  rarity        :string
#  value         :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer
#  room_id       :integer
#
require "rails_helper"

RSpec.describe GridItem, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
