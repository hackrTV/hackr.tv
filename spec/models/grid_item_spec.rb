# == Schema Information
#
# Table name: grid_items
# Database name: primary
#
#  id                      :integer          not null, primary key
#  description             :text
#  item_type               :string
#  name                    :string
#  properties              :json
#  quantity                :integer          default(1), not null
#  rarity                  :string
#  value                   :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  grid_hackr_id           :integer
#  grid_item_definition_id :integer          not null
#  grid_mining_rig_id      :integer
#  room_id                 :integer
#
# Indexes
#
#  index_grid_items_on_grid_hackr_id            (grid_hackr_id)
#  index_grid_items_on_grid_item_definition_id  (grid_item_definition_id)
#  index_grid_items_on_grid_mining_rig_id       (grid_mining_rig_id)
#
# Foreign Keys
#
#  grid_item_definition_id  (grid_item_definition_id => grid_item_definitions.id)
#
require "rails_helper"

RSpec.describe GridItem, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
