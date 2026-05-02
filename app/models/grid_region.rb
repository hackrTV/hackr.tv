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
class GridRegion < ApplicationRecord
  has_paper_trail

  belongs_to :hospital_room, class_name: "GridRoom", optional: true
  belongs_to :containment_room, class_name: "GridRoom", optional: true
  belongs_to :facility_exit_room, class_name: "GridRoom", optional: true
  belongs_to :facility_bribe_exit_room, class_name: "GridRoom", optional: true
  belongs_to :cell_block_room, class_name: "GridRoom", optional: true
  belongs_to :sally_port_room, class_name: "GridRoom", optional: true

  has_many :grid_zones, dependent: :restrict_with_error
  has_many :grid_rooms, through: :grid_zones

  ROOM_FK_FIELDS = %i[
    hospital_room_id containment_room_id cell_block_room_id
    sally_port_room_id facility_exit_room_id facility_bribe_exit_room_id
  ].freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :room_fks_belong_to_region

  private

  def room_fks_belong_to_region
    return unless persisted?

    region_room_ids = nil # lazy-loaded

    ROOM_FK_FIELDS.each do |field|
      room_id = send(field)
      next if room_id.nil?

      region_room_ids ||= grid_rooms.pluck(:id).to_set
      unless region_room_ids.include?(room_id)
        label = field.to_s.sub(/_id$/, "").humanize
        errors.add(field, "must be a room within this region (#{label})")
      end
    end
  end
end
