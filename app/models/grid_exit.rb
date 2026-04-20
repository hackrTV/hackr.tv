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
class GridExit < ApplicationRecord
  has_paper_trail

  belongs_to :from_room, class_name: "GridRoom", foreign_key: :from_room_id
  belongs_to :to_room, class_name: "GridRoom", foreign_key: :to_room_id
  belongs_to :requires_item, class_name: "GridItem", optional: true

  validates :direction, presence: true,
    format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"},
    length: {maximum: 80}
  validates :from_room_id, uniqueness: {scope: :direction, message: "already has an exit in this direction"}
end
