require "rails_helper"

RSpec.describe Grid::SalvageService do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:gpu_def) do
    create(:grid_item_definition, :component,
      slug: "basic-gpu", name: "Basic GPU", value: 5)
  end

  let(:wafer_def) do
    create(:grid_item_definition, slug: "raw-silicon-wafer",
      name: "Raw Silicon Wafer", item_type: "material", rarity: "scrap", value: 2)
  end

  let(:fragment_def) do
    create(:grid_item_definition, slug: "corrupted-shader-fragment",
      name: "Corrupted Shader Fragment", item_type: "material", rarity: "scrap", value: 2)
  end

  let!(:item) do
    GridItem.create!(gpu_def.item_attributes.merge(grid_hackr: hackr, quantity: 1))
  end

  describe ".salvage!" do
    context "with no salvage yields defined" do
      it "destroys the item and returns XP only" do
        result = described_class.salvage!(hackr: hackr, item: item)

        expect(result.xp_awarded).to eq(5)
        expect(result.yielded_items).to be_empty
        expect(result.item_name).to eq("Basic GPU")
        expect { item.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "grants XP to the hackr" do
        old_xp = hackr.stat("xp").to_i
        result = described_class.salvage!(hackr: hackr, item: item)
        expect(hackr.stat("xp").to_i).to eq(old_xp + 5)
      end
    end

    context "with salvage yields defined" do
      before do
        GridSalvageYield.create!(source_definition: gpu_def, output_definition: wafer_def, quantity: 3, position: 0)
        GridSalvageYield.create!(source_definition: gpu_def, output_definition: fragment_def, quantity: 1, position: 1)
      end

      it "destroys the item and returns yield info" do
        result = described_class.salvage!(hackr: hackr, item: item)

        expect(result.xp_awarded).to eq(5)
        expect(result.yielded_items).to eq([
          {name: "Raw Silicon Wafer", quantity: 3},
          {name: "Corrupted Shader Fragment", quantity: 1}
        ])
        expect { item.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "creates yield items in hackr inventory" do
        expect { described_class.salvage!(hackr: hackr, item: item) }
          .to change { hackr.grid_items.count }.by(1) # -1 destroyed + 2 created = +1

        wafer = hackr.grid_items.find_by(grid_item_definition: wafer_def)
        expect(wafer).to be_present
        expect(wafer.quantity).to eq(3)

        fragment = hackr.grid_items.find_by(grid_item_definition: fragment_def)
        expect(fragment).to be_present
        expect(fragment.quantity).to eq(1)
      end

      it "stacks yields into existing inventory items" do
        existing = GridItem.create!(wafer_def.item_attributes.merge(grid_hackr: hackr, quantity: 2))

        described_class.salvage!(hackr: hackr, item: item)

        expect(existing.reload.quantity).to eq(5) # 2 + 3
        expect(hackr.grid_items.where(grid_item_definition: wafer_def).count).to eq(1)
      end
    end

    context "with quantity > 1" do
      before { item.update!(quantity: 3) }

      it "decrements quantity instead of destroying" do
        described_class.salvage!(hackr: hackr, item: item)
        expect(item.reload.quantity).to eq(2)
      end
    end

    context "with unicorn rarity" do
      let(:unicorn_def) do
        create(:grid_item_definition, :unicorn, slug: "unicorn-item", name: "Unicorn Item", value: 999)
      end

      let!(:unicorn_item) do
        GridItem.create!(unicorn_def.item_attributes.merge(grid_hackr: hackr))
      end

      it "raises ArgumentError" do
        expect {
          described_class.salvage!(hackr: hackr, item: unicorn_item)
        }.to raise_error(ArgumentError, /UNICORN/)
      end
    end

    context "with minimum XP" do
      let(:zero_val_def) do
        create(:grid_item_definition, slug: "zero-val", name: "Zero", value: 0)
      end

      let!(:zero_item) do
        GridItem.create!(zero_val_def.item_attributes.merge(grid_hackr: hackr))
      end

      it "awards at least 1 XP" do
        result = described_class.salvage!(hackr: hackr, item: zero_item)
        expect(result.xp_awarded).to eq(1)
      end
    end

    context "transaction safety" do
      before do
        GridSalvageYield.create!(source_definition: gpu_def, output_definition: wafer_def, quantity: 3, position: 0)
      end

      it "rolls back item destruction if yield creation fails" do
        allow(GridItem).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

        expect {
          described_class.salvage!(hackr: hackr, item: item) rescue nil
        }.not_to change { item.reload.quantity }
      end
    end
  end
end
