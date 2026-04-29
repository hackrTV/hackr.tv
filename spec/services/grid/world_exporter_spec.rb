# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::WorldExporter do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room1) { create(:grid_room, grid_zone: zone, name: "Hub Alpha", slug: "hub-alpha", room_type: "hub", map_x: 0, map_y: 0) }
  let(:room2) { create(:grid_room, grid_zone: zone, name: "Transit Beta", slug: "transit-beta", room_type: "transit", map_x: 1, map_y: 0) }

  describe "#export_all" do
    it "writes YAML files to the target directory" do
      room1
      room2
      create(:grid_exit, from_room: room1, to_room: room2, direction: "east")

      Dir.mktmpdir do |dir|
        described_class.new.export_all(dir: dir)

        %w[
          regions.yml zones.yml rooms.yml exits.yml mobs.yml
          item_definitions.yml salvage_yields.yml items.yml
          achievements.yml shop_listings.yml missions.yml
          schematics.yml breach_templates.yml breach_encounters.yml
          factions.yml
        ].each do |file|
          expect(File.exist?(File.join(dir, file))).to be(true), "Missing #{file}"
        end
      end
    end

    it "exports rooms with slug cross-references" do
      room1
      Dir.mktmpdir do |dir|
        described_class.new.export_all(dir: dir)
        data = YAML.load_file(File.join(dir, "rooms.yml"))
        exported = data["rooms"].find { |r| r["slug"] == room1.slug }
        expect(exported["name"]).to eq("Hub Alpha")
        expect(exported["zone_slug"]).to eq(zone.slug)
      end
    end

    it "exports map_x and map_y for rooms with stored coordinates" do
      room1
      Dir.mktmpdir do |dir|
        described_class.new.export_all(dir: dir)
        data = YAML.load_file(File.join(dir, "rooms.yml"))
        exported = data["rooms"].find { |r| r["slug"] == room1.slug }
        expect(exported["map_x"]).to eq(0)
        expect(exported["map_y"]).to eq(0)
      end
    end

    it "omits map_x/map_y for rooms without stored coordinates" do
      room = create(:grid_room, grid_zone: zone, map_x: nil, map_y: nil)
      Dir.mktmpdir do |dir|
        described_class.new.export_all(dir: dir)
        data = YAML.load_file(File.join(dir, "rooms.yml"))
        exported = data["rooms"].find { |r| r["slug"] == room.slug }
        expect(exported).not_to have_key("map_x")
        expect(exported).not_to have_key("map_y")
      end
    end

    it "exports exits with room slug references" do
      create(:grid_exit, from_room: room1, to_room: room2, direction: "east")
      Dir.mktmpdir do |dir|
        described_class.new.export_all(dir: dir)
        data = YAML.load_file(File.join(dir, "exits.yml"))
        exported = data["exits"].find { |e| e["from_room_slug"] == room1.slug }
        expect(exported["to_room_slug"]).to eq(room2.slug)
        expect(exported["direction"]).to eq("east")
      end
    end

    it "exports mobs with room slug references" do
      create(:grid_mob, grid_room: room1, name: "Guard", mob_type: "lore")
      Dir.mktmpdir do |dir|
        described_class.new.export_all(dir: dir)
        data = YAML.load_file(File.join(dir, "mobs.yml"))
        exported = data["mobs"].find { |m| m["name"] == "Guard" }
        expect(exported["room_slug"]).to eq(room1.slug)
      end
    end

    it "exports breach encounters with template and room slugs" do
      template = create(:grid_breach_template, published: true)
      create(:grid_breach_encounter, grid_breach_template: template, grid_room: room1)
      Dir.mktmpdir do |dir|
        described_class.new.export_all(dir: dir)
        data = YAML.load_file(File.join(dir, "breach_encounters.yml"))
        expect(data["breach_encounters"].size).to eq(1)
        expect(data["breach_encounters"][0]["template_slug"]).to eq(template.slug)
        expect(data["breach_encounters"][0]["room_slug"]).to eq(room1.slug)
      end
    end

    it "excludes den rooms from export" do
      den = create(:grid_room, :den, grid_zone: zone)
      Dir.mktmpdir do |dir|
        described_class.new.export_all(dir: dir)
        data = YAML.load_file(File.join(dir, "rooms.yml"))
        slugs = data["rooms"].map { |r| r["slug"] }
        expect(slugs).not_to include(den.slug)
      end
    end
  end

  describe "#to_tar_gz" do
    it "returns a valid gzipped tar archive" do
      room1
      data = described_class.new.to_tar_gz
      expect(data).to be_a(String)
      expect(data.bytes[0..1]).to eq([0x1f, 0x8b]) # gzip magic bytes

      # Verify it contains world/*.yml files
      io = StringIO.new(data)
      filenames = []
      Zlib::GzipReader.wrap(io) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          tar.each { |entry| filenames << entry.full_name }
        end
      end
      expect(filenames).to include("world/rooms.yml")
      expect(filenames).to include("world/exits.yml")
    end
  end
end
