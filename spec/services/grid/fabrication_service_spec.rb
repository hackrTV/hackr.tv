require "rails_helper"

RSpec.describe Grid::FabricationService do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:wafer_def) do
    create(:grid_item_definition, slug: "raw-silicon-wafer",
      name: "Raw Silicon Wafer", item_type: "material", rarity: "scrap", value: 2)
  end

  let(:fragment_def) do
    create(:grid_item_definition, slug: "corrupted-shader-fragment",
      name: "Corrupted Shader Fragment", item_type: "material", rarity: "scrap", value: 2)
  end

  let(:cpu_def) do
    create(:grid_item_definition, :component,
      slug: "basic-cpu", name: "Basic CPU", value: 8)
  end

  let(:schematic) do
    s = GridSchematic.create!(
      slug: "fab-basic-cpu", name: "Fabricate Basic CPU",
      output_definition: cpu_def, output_quantity: 1, xp_reward: 15
    )
    GridSchematicIngredient.create!(grid_schematic: s, input_definition: wafer_def, quantity: 3, position: 0)
    GridSchematicIngredient.create!(grid_schematic: s, input_definition: fragment_def, quantity: 1, position: 1)
    s
  end

  describe ".fabricate!" do
    context "happy path" do
      before do
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 5))
        GridItem.create!(fragment_def.item_attributes.merge(grid_hackr: hackr, quantity: 2))
      end

      it "consumes ingredients and grants output" do
        result = described_class.fabricate!(hackr: hackr, schematic: schematic)

        expect(result.xp_awarded).to eq(15)
        expect(result.output_item_name).to eq("Basic CPU")
        expect(result.output_quantity).to eq(1)
        expect(result.schematic_name).to eq("Fabricate Basic CPU")

        # Ingredients consumed
        wafer = hackr.grid_items.find_by(grid_item_definition: wafer_def)
        expect(wafer.quantity).to eq(2) # 5 - 3

        fragment = hackr.grid_items.find_by(grid_item_definition: fragment_def)
        expect(fragment.quantity).to eq(1) # 2 - 1

        # Output created
        cpu = hackr.grid_items.find_by(grid_item_definition: cpu_def)
        expect(cpu).to be_present
        expect(cpu.quantity).to eq(1)
      end

      it "grants XP" do
        old_xp = hackr.stat("xp").to_i
        described_class.fabricate!(hackr: hackr, schematic: schematic)
        expect(hackr.stat("xp").to_i).to eq(old_xp + 15)
      end
    end

    context "stacking output" do
      before do
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 5))
        GridItem.create!(fragment_def.item_attributes.merge(grid_hackr: hackr, quantity: 2))
        GridItem.create!(cpu_def.item_attributes.merge(grid_hackr: hackr, quantity: 1))
      end

      it "stacks output into existing inventory" do
        described_class.fabricate!(hackr: hackr, schematic: schematic)

        cpu = hackr.grid_items.find_by(grid_item_definition: cpu_def)
        expect(cpu.quantity).to eq(2) # 1 + 1
        expect(hackr.grid_items.where(grid_item_definition: cpu_def).count).to eq(1)
      end
    end

    context "multi-quantity output" do
      let(:multi_schematic) do
        s = GridSchematic.create!(
          slug: "fab-multi", name: "Fab Multi",
          output_definition: cpu_def, output_quantity: 3, xp_reward: 0
        )
        GridSchematicIngredient.create!(grid_schematic: s, input_definition: wafer_def, quantity: 1, position: 0)
        s
      end

      before do
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 5))
      end

      it "grants output_quantity items" do
        result = described_class.fabricate!(hackr: hackr, schematic: multi_schematic)

        expect(result.output_quantity).to eq(3)
        cpu = hackr.grid_items.find_by(grid_item_definition: cpu_def)
        expect(cpu.quantity).to eq(3)
      end
    end

    context "insufficient ingredients" do
      before do
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 1)) # need 3
        GridItem.create!(fragment_def.item_attributes.merge(grid_hackr: hackr, quantity: 2))
      end

      it "raises IngredientsInsufficient" do
        expect {
          described_class.fabricate!(hackr: hackr, schematic: schematic)
        }.to raise_error(
          Grid::FabricationService::IngredientsInsufficient,
          /Raw Silicon Wafer.*need 3.*have 1/
        )
      end

      it "does not consume any ingredients" do
        begin
          described_class.fabricate!(hackr: hackr, schematic: schematic)
        rescue Grid::FabricationService::IngredientsInsufficient
          nil
        end

        wafer = hackr.grid_items.find_by(grid_item_definition: wafer_def)
        expect(wafer.quantity).to eq(1) # unchanged
      end
    end

    context "missing ingredient entirely" do
      before do
        # Only have wafers, no fragments at all
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 5))
      end

      it "raises IngredientsInsufficient" do
        expect {
          described_class.fabricate!(hackr: hackr, schematic: schematic)
        }.to raise_error(
          Grid::FabricationService::IngredientsInsufficient,
          /Corrupted Shader Fragment.*need 1.*have 0/
        )
      end
    end

    context "ingredient consumed to zero destroys the row" do
      before do
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 3)) # exact match
        GridItem.create!(fragment_def.item_attributes.merge(grid_hackr: hackr, quantity: 1)) # exact match
      end

      it "destroys ingredient items consumed entirely" do
        described_class.fabricate!(hackr: hackr, schematic: schematic)

        expect(hackr.grid_items.find_by(grid_item_definition: wafer_def)).to be_nil
        expect(hackr.grid_items.find_by(grid_item_definition: fragment_def)).to be_nil
      end
    end

    context "fragmented stacks" do
      before do
        # Two separate stacks of wafers: 2 + 2 = 4, need 3
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 2))
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 2))
        GridItem.create!(fragment_def.item_attributes.merge(grid_hackr: hackr, quantity: 1))
      end

      it "consumes across stacks correctly" do
        described_class.fabricate!(hackr: hackr, schematic: schematic)

        wafers = hackr.grid_items.where(grid_item_definition: wafer_def)
        total_qty = wafers.sum(:quantity)
        expect(total_qty).to eq(1) # 4 - 3 = 1
      end
    end

    context "zero XP reward" do
      let(:no_xp_schematic) do
        s = GridSchematic.create!(
          slug: "no-xp", name: "No XP",
          output_definition: cpu_def, output_quantity: 1, xp_reward: 0
        )
        GridSchematicIngredient.create!(grid_schematic: s, input_definition: wafer_def, quantity: 1, position: 0)
        s
      end

      before do
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 5))
      end

      it "skips XP grant and returns leveled_up: false" do
        old_xp = hackr.stat("xp").to_i
        result = described_class.fabricate!(hackr: hackr, schematic: no_xp_schematic)

        expect(result.xp_awarded).to eq(0)
        expect(result.xp_result[:leveled_up]).to be false
        expect(hackr.stat("xp").to_i).to eq(old_xp)
      end
    end

    context "transaction safety" do
      before do
        GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 5))
        GridItem.create!(fragment_def.item_attributes.merge(grid_hackr: hackr, quantity: 2))
      end

      it "rolls back ingredient consumption if output creation fails" do
        allow(Grid::Inventory).to receive(:grant_item!).and_raise(ActiveRecord::RecordInvalid)

        expect {
          begin
            described_class.fabricate!(hackr: hackr, schematic: schematic)
          rescue ActiveRecord::RecordInvalid
            nil
          end
        }.not_to change {
          hackr.grid_items.find_by(grid_item_definition: wafer_def).quantity
        }
      end
    end
  end
end
