# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_starting_rooms
# Database name: primary
#
#  id           :integer          not null, primary key
#  active       :boolean          default(TRUE), not null
#  blurb        :text             not null
#  name         :string           not null
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  grid_room_id :integer          not null
#
# Indexes
#
#  index_grid_starting_rooms_on_grid_room_id  (grid_room_id) UNIQUE
#
# Foreign Keys
#
#  grid_room_id  (grid_room_id => grid_rooms.id) ON DELETE => cascade
#
class GridStartingRoom < ApplicationRecord
  has_paper_trail

  belongs_to :grid_room

  validates :name, presence: true
  validates :blurb, presence: true
  validates :grid_room_id, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { active.order(:position, :name) }
end
