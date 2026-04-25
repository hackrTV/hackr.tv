# == Schema Information
#
# Table name: grid_regions
# Database name: primary
#
#  id                          :integer          not null, primary key
#  description                 :text
#  name                        :string           not null
#  slug                        :string           not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  containment_room_id         :integer
#  facility_bribe_exit_room_id :integer
#  facility_exit_room_id       :integer
#  hospital_room_id            :integer
#
# Indexes
#
#  index_grid_regions_on_containment_room_id          (containment_room_id)
#  index_grid_regions_on_facility_bribe_exit_room_id  (facility_bribe_exit_room_id)
#  index_grid_regions_on_facility_exit_room_id        (facility_exit_room_id)
#  index_grid_regions_on_hospital_room_id             (hospital_room_id)
#  index_grid_regions_on_slug                         (slug) UNIQUE
#
# Foreign Keys
#
#  containment_room_id          (containment_room_id => grid_rooms.id) ON DELETE => nullify
#  facility_bribe_exit_room_id  (facility_bribe_exit_room_id => grid_rooms.id) ON DELETE => nullify
#  facility_exit_room_id        (facility_exit_room_id => grid_rooms.id) ON DELETE => nullify
#  hospital_room_id             (hospital_room_id => grid_rooms.id) ON DELETE => nullify
#
class GridRegion < ApplicationRecord
  has_paper_trail

  belongs_to :hospital_room, class_name: "GridRoom", optional: true
  belongs_to :containment_room, class_name: "GridRoom", optional: true
  belongs_to :facility_exit_room, class_name: "GridRoom", optional: true
  belongs_to :facility_bribe_exit_room, class_name: "GridRoom", optional: true

  has_many :grid_zones, dependent: :restrict_with_error
  has_many :grid_rooms, through: :grid_zones

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
