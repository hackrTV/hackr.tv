# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DataAudit::Checks" do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }

  describe DataAudit::Checks::RoomNoExits do
    it "flags rooms with no exits" do
      room = create(:grid_room, grid_zone: zone, description: "A room")
      # No exits created
      violations = described_class.new.violations
      fps = violations.map { |v| v[:subject_id] }
      expect(fps).to include(room.id)
    end

    it "does not flag rooms with exits" do
      room = create(:grid_room, grid_zone: zone)
      target = create(:grid_room, grid_zone: zone)
      create(:grid_exit, from_room: room, to_room: target, direction: "north")

      violations = described_class.new.violations
      fps = violations.map { |v| v[:subject_id] }
      expect(fps).not_to include(room.id)
    end

    it "does not flag den rooms" do
      create(:grid_room, :den, grid_zone: zone)
      violations = described_class.new.violations
      den_violations = violations.select { |v| v[:title].include?("Den") }
      expect(den_violations).to be_empty
    end
  end

  describe DataAudit::Checks::MissionNoGiver do
    it "flags published missions with no giver" do
      # Model validates giver presence on published missions, so simulate
      # the nullified-FK case (mob deleted after publish) via direct update
      mission = create(:grid_mission, published: true)
      mission.update_column(:giver_mob_id, nil)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).to include(mission.id)
    end

    it "does not flag published missions with a giver" do
      mission = create(:grid_mission, published: true)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).not_to include(mission.id)
    end

    it "does not flag unpublished missions" do
      mission = create(:grid_mission, :unpublished, giver_mob: nil)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).not_to include(mission.id)
    end
  end

  describe DataAudit::Checks::MissionBlockedPrereq do
    it "flags published missions whose prereq is unpublished" do
      prereq = create(:grid_mission, :unpublished)
      mission = create(:grid_mission, published: true, prereq_mission: prereq)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).to include(mission.id)
    end

    it "does not flag missions with published prereqs" do
      prereq = create(:grid_mission, published: true)
      mission = create(:grid_mission, published: true, prereq_mission: prereq)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).not_to include(mission.id)
    end
  end

  describe DataAudit::Checks::VendorNoListings do
    it "flags vendor mobs with no listings" do
      vendor = create(:grid_mob, :vendor)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).to include(vendor.id)
    end

    it "does not flag vendors with listings" do
      vendor = create(:grid_mob, :vendor)
      item_def = create(:grid_item_definition)
      create(:grid_shop_listing, grid_mob: vendor, grid_item_definition: item_def)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).not_to include(vendor.id)
    end
  end

  describe DataAudit::Checks::ZoneNoRooms do
    it "flags zones with no rooms" do
      empty_zone = create(:grid_zone, grid_region: region)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).to include(empty_zone.id)
    end

    it "does not flag zones with rooms" do
      zone_with_rooms = create(:grid_zone, grid_region: region)
      create(:grid_room, grid_zone: zone_with_rooms)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).not_to include(zone_with_rooms.id)
    end
  end

  describe DataAudit::Checks::RegionMissingHospital do
    it "flags regions with no hospital room" do
      region # force create before check runs
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).to include(region.id)
    end

    it "does not flag regions with hospital room set" do
      room = create(:grid_room, grid_zone: zone)
      region.update!(hospital_room_id: room.id)
      violations = described_class.new.violations
      ids = violations.map { |v| v[:subject_id] }
      expect(ids).not_to include(region.id)
    end
  end

  describe "all checks" do
    it "every registered check returns an array of hashes with required keys" do
      DataAudit::Registry::CHECKS.each do |check_class|
        check = check_class.new
        violations = check.violations
        expect(violations).to be_an(Array), "#{check_class} did not return Array"
        violations.each do |v|
          expect(v).to have_key(:fingerprint), "#{check_class} violation missing :fingerprint"
          expect(v).to have_key(:check_name), "#{check_class} violation missing :check_name"
          expect(v).to have_key(:title), "#{check_class} violation missing :title"
          expect(v).to have_key(:severity), "#{check_class} violation missing :severity"
          expect(v).to have_key(:domain), "#{check_class} violation missing :domain"
          expect(v).to have_key(:subject_type), "#{check_class} violation missing :subject_type"
          expect(v).to have_key(:subject_id), "#{check_class} violation missing :subject_id"
        end
      end
    end

    it "every check has a valid severity and domain" do
      DataAudit::Registry::CHECKS.each do |check_class|
        check = check_class.new
        expect(DataAuditFlag::SEVERITIES).to include(check.severity), "#{check_class} has invalid severity: #{check.severity}"
        expect(DataAuditFlag::DOMAINS).to include(check.domain), "#{check_class} has invalid domain: #{check.domain}"
      end
    end
  end
end
