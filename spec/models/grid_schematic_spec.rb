require "rails_helper"

RSpec.describe GridSchematic do
  let(:output_def) { create(:grid_item_definition, slug: "output-item") }

  describe "validations" do
    it "is valid with valid attributes" do
      schematic = described_class.new(
        slug: "test-schematic", name: "Test", output_definition: output_def
      )
      expect(schematic).to be_valid
    end

    it "requires slug" do
      schematic = described_class.new(name: "Test", output_definition: output_def)
      expect(schematic).not_to be_valid
      expect(schematic.errors[:slug]).to be_present
    end

    it "requires unique slug" do
      described_class.create!(slug: "taken", name: "First", output_definition: output_def)
      duplicate = described_class.new(slug: "taken", name: "Second", output_definition: output_def)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end

    it "validates slug format" do
      schematic = described_class.new(slug: "INVALID SLUG!", name: "Test", output_definition: output_def)
      expect(schematic).not_to be_valid
      expect(schematic.errors[:slug]).to include("only lowercase letters, numbers, and hyphens")
    end

    it "requires name" do
      schematic = described_class.new(slug: "test", output_definition: output_def, name: nil)
      expect(schematic).not_to be_valid
      expect(schematic.errors[:name]).to be_present
    end

    it "requires output_quantity >= 1" do
      schematic = described_class.new(slug: "test", name: "Test", output_definition: output_def, output_quantity: 0)
      expect(schematic).not_to be_valid
      expect(schematic.errors[:output_quantity]).to be_present
    end

    it "requires xp_reward >= 0" do
      schematic = described_class.new(slug: "test", name: "Test", output_definition: output_def, xp_reward: -1)
      expect(schematic).not_to be_valid
      expect(schematic.errors[:xp_reward]).to be_present
    end

    it "requires required_clearance 0-99" do
      schematic = described_class.new(slug: "test", name: "Test", output_definition: output_def, required_clearance: 100)
      expect(schematic).not_to be_valid
      expect(schematic.errors[:required_clearance]).to be_present
    end
  end

  describe "#to_param" do
    it "returns slug" do
      schematic = described_class.new(slug: "my-schematic")
      expect(schematic.to_param).to eq("my-schematic")
    end
  end

  describe ".published" do
    it "returns only published schematics" do
      pub = described_class.create!(slug: "pub", name: "Pub", output_definition: output_def, published: true)
      described_class.create!(slug: "draft", name: "Draft", output_definition: output_def, published: false)

      expect(described_class.published).to eq([pub])
    end
  end

  describe ".ordered" do
    it "orders by position then name" do
      s2 = described_class.create!(slug: "b", name: "Beta", output_definition: output_def, position: 1)
      s1 = described_class.create!(slug: "a", name: "Alpha", output_definition: output_def, position: 0)

      expect(described_class.ordered.to_a).to eq([s1, s2])
    end
  end

  describe "#craftable_by?" do
    let(:zone) { create(:grid_zone) }
    let(:room) { create(:grid_room, grid_zone: zone) }
    let(:hackr) { create(:grid_hackr, current_room: room) }

    context "clearance gate" do
      it "returns true when hackr meets clearance" do
        hackr.set_stat!("clearance", 5)
        schematic = described_class.create!(
          slug: "gated", name: "Gated", output_definition: output_def, required_clearance: 5
        )
        expect(schematic.craftable_by?(hackr)).to be true
      end

      it "returns false when hackr below clearance" do
        hackr.set_stat!("clearance", 2)
        schematic = described_class.create!(
          slug: "gated", name: "Gated", output_definition: output_def, required_clearance: 5
        )
        expect(schematic.craftable_by?(hackr)).to be false
      end
    end

    context "mission gate" do
      let(:mission) do
        mob = create(:grid_mob, grid_room: room)
        create(:grid_mission, slug: "required-mission", giver_mob: mob, published: true)
      end

      it "returns true when mission completed" do
        create(:grid_hackr_mission, :completed, grid_hackr: hackr, grid_mission: mission)
        schematic = described_class.create!(
          slug: "mission-gated", name: "Mission Gated",
          output_definition: output_def, required_mission_slug: "required-mission"
        )
        expect(schematic.craftable_by?(hackr)).to be true
      end

      it "returns false when mission not completed" do
        schematic = described_class.create!(
          slug: "mission-gated", name: "Mission Gated",
          output_definition: output_def, required_mission_slug: "required-mission"
        )
        expect(schematic.craftable_by?(hackr)).to be false
      end
    end

    context "achievement gate" do
      let(:achievement) do
        create(:grid_achievement, slug: "required-achievement",
          trigger_type: "manual", category: "grid")
      end

      it "returns true when achievement earned" do
        create(:grid_hackr_achievement, grid_hackr: hackr, grid_achievement: achievement)
        schematic = described_class.create!(
          slug: "ach-gated", name: "Achievement Gated",
          output_definition: output_def, required_achievement_slug: "required-achievement"
        )
        expect(schematic.craftable_by?(hackr)).to be true
      end

      it "returns false when achievement not earned" do
        achievement # ensure it exists
        schematic = described_class.create!(
          slug: "ach-gated", name: "Achievement Gated",
          output_definition: output_def, required_achievement_slug: "required-achievement"
        )
        expect(schematic.craftable_by?(hackr)).to be false
      end
    end

    context "no gates" do
      it "returns true with all nil gates" do
        schematic = described_class.create!(
          slug: "open", name: "Open", output_definition: output_def
        )
        expect(schematic.craftable_by?(hackr)).to be true
      end
    end
  end
end
