# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::NameResolver do
  describe ".resolve" do
    let!(:room) { create(:grid_room) }
    let!(:mob_coordinator) { create(:grid_mob, name: "Fracture Network Coordinator", grid_room: room) }
    let!(:mob_merchant) { create(:grid_mob, name: "Salvage Merchant", grid_room: room) }

    it "returns exact case-insensitive match" do
      result = described_class.resolve(room.grid_mobs, "fracture network coordinator")
      expect(result).to eq(mob_coordinator)
    end

    it "returns single partial match" do
      result = described_class.resolve(room.grid_mobs, "coord")
      expect(result).to eq(mob_coordinator)
    end

    it "returns nil when no match" do
      result = described_class.resolve(room.grid_mobs, "zzz")
      expect(result).to be_nil
    end

    it "raises AmbiguousMatch when multiple partial matches" do
      create(:grid_mob, name: "Network Node", grid_room: room)
      expect {
        described_class.resolve(room.grid_mobs, "network")
      }.to raise_error(Grid::NameResolver::AmbiguousMatch) { |e|
        expect(e.candidates).to contain_exactly("Fracture Network Coordinator", "Network Node")
      }
    end

    it "prefers exact match over partial matches" do
      create(:grid_mob, name: "Net", grid_room: room)
      create(:grid_mob, name: "Network Node", grid_room: room)
      result = described_class.resolve(room.grid_mobs, "net")
      expect(result.name).to eq("Net")
    end

    it "returns nil for empty input" do
      result = described_class.resolve(room.grid_mobs, "")
      expect(result).to be_nil
    end

    it "returns nil for nil input" do
      result = described_class.resolve(room.grid_mobs, nil)
      expect(result).to be_nil
    end

    it "sanitizes LIKE wildcards in input" do
      create(:grid_mob, name: "50% Off Vendor", grid_room: room)
      result = described_class.resolve(room.grid_mobs, "50%")
      expect(result.name).to eq("50% Off Vendor")
    end

    it "sanitizes underscore in input" do
      # _ is a LIKE wildcard matching any single character
      result = described_class.resolve(room.grid_mobs, "f_acture")
      expect(result).to be_nil
    end

    context "with custom column" do
      let!(:hackr) { create(:grid_hackr) }
      let!(:other_hackr) { create(:grid_hackr, hackr_alias: "XERAEN") }

      before do
        hackr.update!(current_room: room)
        other_hackr.update!(current_room: room)
      end

      it "resolves by hackr_alias" do
        result = described_class.resolve(room.grid_hackrs, "xer", column: "hackr_alias")
        expect(result).to eq(other_hackr)
      end
    end

    context "with slug column" do
      let!(:schematic1) { create(:grid_schematic, slug: "neural-patch-mk-iv", published: true) }
      let!(:schematic2) { create(:grid_schematic, slug: "neural-spike", published: true) }

      it "resolves partial slug uniquely" do
        result = described_class.resolve(GridSchematic.published, "neural-patch", column: "slug")
        expect(result).to eq(schematic1)
      end

      it "raises AmbiguousMatch for ambiguous slug" do
        expect {
          described_class.resolve(GridSchematic.published, "neural", column: "slug")
        }.to raise_error(Grid::NameResolver::AmbiguousMatch)
      end
    end

    it "sanitizes backslash in input" do
      create(:grid_mob, name: "Back\\slash Mob", grid_room: room)
      result = described_class.resolve(room.grid_mobs, "back\\slash")
      expect(result.name).to eq("Back\\slash Mob")
    end

    it "resolves against an unscoped model class" do
      schematic = create(:grid_schematic, slug: "test-resolver", published: true)
      result = described_class.resolve(GridSchematic, "test-resolver", column: "slug")
      expect(result).to eq(schematic)
    end

    it "raises ArgumentError for disallowed column" do
      expect {
        described_class.resolve(room.grid_mobs, "test", column: "'; DROP TABLE--")
      }.to raise_error(ArgumentError, /not in allowlist/)
    end
  end

  describe ".resolve_key" do
    let(:topics) do
      {
        "missions" => {"response" => "Here are missions"},
        "mining" => {"response" => "About mining"},
        "network" => {"response" => "Network info"},
        "news" => {"response" => "Latest news"}
      }
    end

    it "returns exact match" do
      result = described_class.resolve_key(topics, "missions")
      expect(result[:key]).to eq("missions")
      expect(result[:value]).to eq({"response" => "Here are missions"})
    end

    it "returns exact match case-insensitively" do
      result = described_class.resolve_key(topics, "MISSIONS")
      expect(result[:key]).to eq("missions")
    end

    it "returns single partial match" do
      result = described_class.resolve_key(topics, "miss")
      expect(result[:key]).to eq("missions")
    end

    it "returns nil when no match" do
      result = described_class.resolve_key(topics, "zzz")
      expect(result).to be_nil
    end

    it "raises AmbiguousMatch when multiple partial matches" do
      expect {
        described_class.resolve_key(topics, "ne")
      }.to raise_error(Grid::NameResolver::AmbiguousMatch) { |e|
        expect(e.candidates).to contain_exactly("network", "news")
      }
    end

    it "prefers exact match over partials" do
      hash = {"net" => {"response" => "exact"}, "network" => {"response" => "partial"}}
      result = described_class.resolve_key(hash, "net")
      expect(result[:key]).to eq("net")
      expect(result[:value]["response"]).to eq("exact")
    end

    it "returns nil for empty input" do
      result = described_class.resolve_key(topics, "")
      expect(result).to be_nil
    end

    it "returns nil for nil hash" do
      result = described_class.resolve_key(nil, "test")
      expect(result).to be_nil
    end

    it "returns nil for non-hash input" do
      result = described_class.resolve_key("not a hash", "test")
      expect(result).to be_nil
    end
  end

  describe "integration with CommandParser" do
    let!(:hackr) { create(:grid_hackr) }
    let!(:room) { create(:grid_room) }
    let!(:item) { create(:grid_item, name: "Laser Rifle", grid_hackr: hackr, room: nil) }

    before { hackr.update!(current_room: room) }

    it "resolves partial item name in take command" do
      item.update!(room: room, grid_hackr: nil)
      result = Grid::CommandParser.new(hackr, "take laser").execute
      expect(result[:output]).to include("Laser Rifle")
      expect(result[:output]).to include("You take")
    end

    it "shows disambiguation for ambiguous input" do
      create(:grid_item, name: "Laser Pistol", room: room, grid_hackr: nil)
      item.update!(room: room, grid_hackr: nil)
      result = Grid::CommandParser.new(hackr, "take laser").execute
      expect(result[:output]).to include("Did you mean")
      expect(result[:output]).to include("Laser Rifle")
      expect(result[:output]).to include("Laser Pistol")
    end

    it "resolves partial mob name in talk command" do
      create(:grid_mob, name: "Fracture Network Coordinator", grid_room: room,
        dialogue_tree: {"greeting" => "Hello", "topics" => {}})
      result = Grid::CommandParser.new(hackr, "talk coord").execute
      output = result.is_a?(Hash) ? result[:output] : result
      expect(output).to include("Fracture Network Coordinator")
    end
  end
end
