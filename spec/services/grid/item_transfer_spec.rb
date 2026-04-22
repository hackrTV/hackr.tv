# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::ItemTransfer do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:definition) { create(:grid_item_definition, item_type: "material", max_stack: 10) }

  describe ".move! to :inventory" do
    let(:floor_item) { create(:grid_item, grid_item_definition: definition, room: room, quantity: 5) }

    before { floor_item }

    it "moves whole stack to inventory (preserves row)" do
      ActiveRecord::Base.transaction do
        qty = described_class.move!(source_item: floor_item, quantity: :all, destination_type: :inventory, destination: hackr)
        expect(qty).to eq(5)
      end
      floor_item.reload
      expect(floor_item.grid_hackr).to eq(hackr)
      expect(floor_item.room).to be_nil
      expect(floor_item.quantity).to eq(5)
    end

    it "splits partial quantity" do
      ActiveRecord::Base.transaction do
        qty = described_class.move!(source_item: floor_item, quantity: 3, destination_type: :inventory, destination: hackr)
        expect(qty).to eq(3)
      end
      floor_item.reload
      expect(floor_item.room).to eq(room)
      expect(floor_item.quantity).to eq(2)

      inv_item = hackr.grid_items.in_inventory(hackr).find_by(grid_item_definition: definition)
      expect(inv_item.quantity).to eq(3)
    end

    it "merges into existing inventory stack" do
      existing = create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 4)
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: floor_item, quantity: 3, destination_type: :inventory, destination: hackr)
      end
      existing.reload
      expect(existing.quantity).to eq(7)
    end

    it "spills overflow into new stack when existing is full" do
      create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 8)
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: floor_item, quantity: 5, destination_type: :inventory, destination: hackr)
      end
      stacks = hackr.grid_items.in_inventory(hackr).where(grid_item_definition: definition).order(:id)
      expect(stacks.map(&:quantity)).to contain_exactly(10, 3)
    end

    it "raises InsufficientQuantity when requesting more than available" do
      expect {
        ActiveRecord::Base.transaction do
          described_class.move!(source_item: floor_item, quantity: 10, destination_type: :inventory, destination: hackr)
        end
      }.to raise_error(Grid::ItemTransfer::InsufficientQuantity, /only have 5/)
    end

    it "raises InventoryFull when no slots available" do
      hackr.inventory_capacity.times do
        create(:grid_item, :in_inventory, grid_hackr: hackr)
      end
      expect {
        ActiveRecord::Base.transaction do
          described_class.move!(source_item: floor_item, quantity: 1, destination_type: :inventory, destination: hackr)
        end
      }.to raise_error(Grid::InventoryErrors::InventoryFull)
    end
  end

  describe ".move! to :room" do
    let(:inv_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 8) }

    before { inv_item }

    it "moves whole stack to room (preserves row)" do
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: inv_item, quantity: :all, destination_type: :room, destination: room)
      end
      inv_item.reload
      expect(inv_item.room).to eq(room)
      expect(inv_item.grid_hackr).to be_nil
    end

    it "splits partial quantity and creates floor row" do
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: inv_item, quantity: 3, destination_type: :room, destination: room)
      end
      inv_item.reload
      expect(inv_item.quantity).to eq(5)

      floor_item = room.grid_items.on_floor(room).find_by(grid_item_definition: definition)
      expect(floor_item.quantity).to eq(3)
    end

    it "merges into existing floor stack" do
      existing_floor = create(:grid_item, grid_item_definition: definition, room: room, quantity: 6)
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: inv_item, quantity: 3, destination_type: :room, destination: room)
      end
      existing_floor.reload
      expect(existing_floor.quantity).to eq(9)
    end

    it "merges and spills into new row when floor stack overflows" do
      create(:grid_item, grid_item_definition: definition, room: room, quantity: 7)
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: inv_item, quantity: 8, destination_type: :room, destination: room)
      end
      floor_items = room.grid_items.on_floor(room).where(grid_item_definition: definition).order(:id)
      expect(floor_items.map(&:quantity)).to contain_exactly(10, 5)
    end

    context "den floor cap" do
      let(:den) { create(:grid_room, :den, grid_zone: zone, owner: hackr) }

      it "raises DestinationFull when den floor is at cap" do
        Grid::DenService::DEN_STORAGE_CAP.times do
          create(:grid_item, grid_item_definition: create(:grid_item_definition), room: den, quantity: 1)
        end
        expect {
          ActiveRecord::Base.transaction do
            described_class.move!(source_item: inv_item, quantity: 1, destination_type: :room, destination: den)
          end
        }.to raise_error(Grid::ItemTransfer::DestinationFull, /Den floor full/)
      end
    end
  end

  describe ".move! to :fixture" do
    let(:fixture_def) { create(:grid_item_definition, :fixture) }
    let(:fixture) { create(:grid_item, :placed_fixture, room: room, grid_item_definition: fixture_def) }
    let(:inv_item) { create(:grid_item, :in_inventory, grid_hackr: hackr, grid_item_definition: definition, quantity: 5) }

    before do
      fixture
      inv_item
    end

    it "moves whole stack into fixture (preserves row)" do
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: inv_item, quantity: :all, destination_type: :fixture, destination: fixture)
      end
      inv_item.reload
      expect(inv_item.container).to eq(fixture)
      expect(inv_item.grid_hackr).to be_nil
    end

    it "splits partial quantity into fixture" do
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: inv_item, quantity: 2, destination_type: :fixture, destination: fixture)
      end
      inv_item.reload
      expect(inv_item.quantity).to eq(3)

      stored = fixture.stored_items.find_by(grid_item_definition: definition)
      expect(stored.quantity).to eq(2)
    end

    it "raises DestinationFull when fixture is at capacity" do
      fixture.storage_capacity.times do
        create(:grid_item, container: fixture, grid_item_definition: create(:grid_item_definition),
          room: nil, grid_hackr: nil)
      end
      expect {
        ActiveRecord::Base.transaction do
          described_class.move!(source_item: inv_item, quantity: 1, destination_type: :fixture, destination: fixture)
        end
      }.to raise_error(Grid::ItemTransfer::DestinationFull)
    end

    it "merges and spills into new slot when fixture stack overflows max_stack" do
      # Existing stack in fixture with 8 of max 10
      create(:grid_item, grid_item_definition: definition, container: fixture,
        room: nil, grid_hackr: nil, quantity: 8)
      # Move 5 from inventory — should fill existing to 10, spill 3 into new slot
      ActiveRecord::Base.transaction do
        described_class.move!(source_item: inv_item, quantity: 5, destination_type: :fixture, destination: fixture)
      end
      # Source destroyed (qty was exactly 5)
      expect(GridItem.find_by(id: inv_item.id)).to be_nil
      stored = fixture.stored_items.where(grid_item_definition: definition).order(:id)
      expect(stored.map(&:quantity)).to contain_exactly(10, 3)
    end
  end
end
