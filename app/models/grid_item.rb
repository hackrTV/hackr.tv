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
class GridItem < ApplicationRecord
  belongs_to :room, class_name: "GridRoom", optional: true
  belongs_to :grid_hackr, optional: true

  validates :name, presence: true
  validates :item_type, inclusion: {in: %w[tool consumable data faction collectible], allow_nil: true}

  scope :in_room, ->(room) { where(room: room, grid_hackr: nil) }
  scope :in_inventory, ->(hackr) { where(grid_hackr: hackr) }
end
