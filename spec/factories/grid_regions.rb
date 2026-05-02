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
#  cell_block_room_id          :integer
#  containment_room_id         :integer
#  facility_bribe_exit_room_id :integer
#  facility_exit_room_id       :integer
#  hospital_room_id            :integer
#  sally_port_room_id          :integer
#
# Indexes
#
#  index_grid_regions_on_cell_block_room_id           (cell_block_room_id)
#  index_grid_regions_on_containment_room_id          (containment_room_id)
#  index_grid_regions_on_facility_bribe_exit_room_id  (facility_bribe_exit_room_id)
#  index_grid_regions_on_facility_exit_room_id        (facility_exit_room_id)
#  index_grid_regions_on_hospital_room_id             (hospital_room_id)
#  index_grid_regions_on_sally_port_room_id           (sally_port_room_id)
#  index_grid_regions_on_slug                         (slug) UNIQUE
#
# Foreign Keys
#
#  cell_block_room_id           (cell_block_room_id => grid_rooms.id) ON DELETE => nullify
#  containment_room_id          (containment_room_id => grid_rooms.id) ON DELETE => nullify
#  facility_bribe_exit_room_id  (facility_bribe_exit_room_id => grid_rooms.id) ON DELETE => nullify
#  facility_exit_room_id        (facility_exit_room_id => grid_rooms.id) ON DELETE => nullify
#  hospital_room_id             (hospital_room_id => grid_rooms.id) ON DELETE => nullify
#  sally_port_room_id           (sally_port_room_id => grid_rooms.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :grid_region do
    sequence(:name) { |n| "Region #{n}" }
    sequence(:slug) { |n| "region-#{n}" }
    description { "A test region in THE PULSE GRID" }
  end
end
