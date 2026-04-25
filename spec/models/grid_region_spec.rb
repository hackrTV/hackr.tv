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
require "rails_helper"

RSpec.describe GridRegion, type: :model do
  subject(:region) { build(:grid_region) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires name" do
      region.name = nil
      expect(region).not_to be_valid
    end

    it "requires slug" do
      region.slug = nil
      expect(region).not_to be_valid
    end

    it "requires unique slug" do
      create(:grid_region, slug: "taken")
      region.slug = "taken"
      expect(region).not_to be_valid
    end
  end

  describe "associations" do
    it "has many grid_zones" do
      region.save!
      zone = create(:grid_zone, grid_region: region)
      expect(region.grid_zones).to include(zone)
    end

    it "has many grid_rooms through grid_zones" do
      region.save!
      zone = create(:grid_zone, grid_region: region)
      room = create(:grid_room, grid_zone: zone)
      expect(region.grid_rooms).to include(room)
    end

    it "restricts deletion when zones exist" do
      region.save!
      create(:grid_zone, grid_region: region)
      expect { region.destroy }.not_to change(GridRegion, :count)
      expect(region.errors[:base]).to be_present
    end
  end
end
