# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::BreachGeneratorService do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region, danger_level: danger_level) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:entry_room) { create(:grid_room, grid_zone: create(:grid_zone, grid_region: region)) }
  let(:hackr) { create(:grid_hackr, current_room: room, zone_entry_room: entry_room) }
  let(:danger_level) { 5 }

  let(:deck_def) do
    create(:grid_item_definition, :gear,
      slug: "gen-test-deck",
      name: "Generator Test Deck",
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
  end

  let!(:deck) do
    item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    item.update!(equipped_slot: "deck")
    item
  end

  let!(:ambient_template) do
    create(:grid_breach_template, :ambient,
      slug: "ambient-test-scan",
      name: "Test Ambient Scan",
      danger_level_min: 1,
      zone_slugs: [],
      min_clearance: 0,
      published: true)
  end

  describe ".ambient_check!" do
    context "when zone danger_level is 0" do
      let(:danger_level) { 0 }

      it "returns nil without rolling" do
        result = described_class.ambient_check!(hackr: hackr, room: room)
        expect(result).to be_nil
      end
    end

    context "when hackr is already in breach" do
      before do
        encounter = create(:grid_breach_encounter, grid_breach_template: create(:grid_breach_template), grid_room: room)
        Grid::BreachService.start!(hackr: hackr, encounter: encounter)
      end

      it "returns nil" do
        result = described_class.ambient_check!(hackr: hackr, room: room)
        expect(result).to be_nil
      end
    end

    context "when roll fails (no encounter triggered)" do
      it "returns nil" do
        allow_any_instance_of(described_class).to receive(:rand).and_return(0.99)
        result = described_class.ambient_check!(hackr: hackr, room: room)
        expect(result).to be_nil
      end
    end

    context "when roll succeeds and DECK equipped" do
      before do
        allow_any_instance_of(described_class).to receive(:rand).and_return(0.01)
      end

      it "starts an ambient BREACH encounter" do
        result = described_class.ambient_check!(hackr: hackr, room: room)

        expect(result).to be_a(Grid::BreachGeneratorService::AmbientResult)
        expect(result.ejected).to be false
        expect(result.display).to include("AMBIENT BREACH")
        expect(result.display).to include("B R E A C H")
        expect(hackr.reload).to be_in_breach
      end

      it "creates a breach with nil encounter (ambient)" do
        described_class.ambient_check!(hackr: hackr, room: room)

        breach = hackr.active_breach
        expect(breach.grid_breach_encounter_id).to be_nil
        expect(breach.grid_breach_template.tier).to eq("ambient")
        expect(breach.state).to eq("active")
      end
    end

    context "when roll succeeds and no DECK equipped" do
      before do
        allow_any_instance_of(described_class).to receive(:rand).and_return(0.01)
        deck.update!(equipped_slot: nil)
      end

      it "auto-fails with tier 1 consequences (vitals drain)" do
        old_energy = hackr.stat("energy")
        old_psyche = hackr.stat("psyche")

        result = described_class.ambient_check!(hackr: hackr, room: room)

        hackr.reload
        expect(result).to be_a(Grid::BreachGeneratorService::AmbientResult)
        expect(result.display).to include("No DECK equipped")
        expect(result.display).to include("ENERGY -20")
        expect(hackr.stat("energy")).to eq([old_energy - 20, 0].max)
        expect(hackr.stat("psyche")).to eq([old_psyche - 20, 0].max)
      end

      it "ejects hackr to zone entry room" do
        result = described_class.ambient_check!(hackr: hackr, room: room)

        expect(result.ejected).to be true
        expect(hackr.reload.current_room_id).to eq(entry_room.id)
      end

      it "does not start a BREACH" do
        described_class.ambient_check!(hackr: hackr, room: room)
        expect(hackr.reload).not_to be_in_breach
      end
    end

    context "when no zone entry room is set" do
      let(:hackr) { create(:grid_hackr, current_room: room, zone_entry_room: nil) }

      before do
        allow_any_instance_of(described_class).to receive(:rand).and_return(0.01)
        deck.update!(equipped_slot: nil)
      end

      it "does not eject (stays in current room)" do
        result = described_class.ambient_check!(hackr: hackr, room: room)

        expect(result.ejected).to be false
        expect(hackr.reload.current_room_id).to eq(room.id)
      end
    end
  end

  describe "template filtering" do
    before do
      allow_any_instance_of(described_class).to receive(:rand).and_return(0.01)
    end

    context "by danger_level_min" do
      let(:danger_level) { 3 }

      let!(:high_danger_template) do
        create(:grid_breach_template, :ambient,
          slug: "ambient-high-danger",
          danger_level_min: 5,
          published: true)
      end

      it "only selects templates with danger_level_min <= zone danger_level" do
        result = described_class.ambient_check!(hackr: hackr, room: room)

        expect(result).not_to be_nil
        breach = hackr.active_breach
        expect(breach.grid_breach_template).to eq(ambient_template)
      end
    end

    context "by zone_slugs" do
      before do
        # Remove the catch-all template so only the zone-locked one exists
        ambient_template.update!(published: false)
      end

      let!(:zone_locked_template) do
        create(:grid_breach_template, :ambient,
          slug: "ambient-zone-locked",
          danger_level_min: 1,
          zone_slugs: ["some-other-zone"],
          published: true)
      end

      it "excludes templates targeting other zones" do
        result = described_class.ambient_check!(hackr: hackr, room: room)

        expect(result).to be_nil
        expect(hackr.reload).not_to be_in_breach
      end
    end

    context "by min_clearance" do
      before do
        # Remove the catch-all template so only the high-clearance one exists
        ambient_template.update!(published: false)
      end

      let!(:high_cl_template) do
        create(:grid_breach_template, :ambient,
          slug: "ambient-high-cl",
          danger_level_min: 1,
          min_clearance: 50,
          published: true)
      end

      it "excludes templates requiring higher clearance than hackr has" do
        result = described_class.ambient_check!(hackr: hackr, room: room)

        expect(result).to be_nil
        expect(hackr.reload).not_to be_in_breach
      end
    end

    context "when no matching templates exist" do
      before { ambient_template.update!(published: false) }

      it "returns nil even when roll succeeds" do
        result = described_class.ambient_check!(hackr: hackr, room: room)
        expect(result).to be_nil
      end
    end
  end
end
