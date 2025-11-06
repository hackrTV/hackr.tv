class GridExit < ApplicationRecord
  belongs_to :from_room, class_name: "GridRoom", foreign_key: :from_room_id
  belongs_to :to_room, class_name: "GridRoom", foreign_key: :to_room_id
  belongs_to :requires_item, class_name: "GridItem", optional: true

  validates :direction, presence: true, inclusion: {in: %w[north south east west up down]}
  validates :from_room_id, uniqueness: {scope: :direction, message: "already has an exit in this direction"}
end
