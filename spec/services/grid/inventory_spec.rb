# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::Inventory do
  let(:hackr) { create(:grid_hackr) }
  let(:definition) { create(:grid_item_definition) }

  describe ".grant_item!" do
    it "creates a new item when hackr has none of that definition" do
      item = nil
      ActiveRecord::Base.transaction do
        item = described_class.grant_item!(hackr: hackr, definition: definition)
      end
      expect(item).to be_persisted
      expect(item.quantity).to eq(1)
      expect(item.grid_hackr).to eq(hackr)
    end

    it "stacks into existing item row" do
      existing = nil
      ActiveRecord::Base.transaction do
        existing = described_class.grant_item!(hackr: hackr, definition: definition, quantity: 3)
      end

      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 2)
      end

      existing.reload
      expect(existing.quantity).to eq(5)
    end

    it "raises InventoryFull when at capacity" do
      16.times do |i|
        d = create(:grid_item_definition, slug: "fill-#{i}", name: "Fill #{i}")
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: d)
        end
      end

      new_def = create(:grid_item_definition, slug: "overflow", name: "Overflow")
      expect {
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: new_def)
        end
      }.to raise_error(Grid::InventoryErrors::InventoryFull)
    end

    it "allows stacking into existing slot when at capacity" do
      16.times do |i|
        d = create(:grid_item_definition, slug: "fill-#{i}", name: "Fill #{i}")
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: d)
        end
      end

      first_def = GridItemDefinition.find_by(slug: "fill-0")
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: first_def)
      end

      item = hackr.grid_items.find_by(grid_item_definition: first_def)
      expect(item.quantity).to eq(2)
    end

    it "splits grant across existing stack and new slot when max_stack exceeded" do
      definition.update!(max_stack: 8)
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 7)
      end

      # Grant 3 more: 1 fills existing to 8, 2 go into new slot
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 3)
      end

      items = hackr.grid_items.where(grid_item_definition: definition).order(:id)
      expect(items.count).to eq(2)
      expect(items.first.quantity).to eq(8) # filled to max
      expect(items.last.quantity).to eq(2)  # remainder in new slot
    end

    it "raises InventoryFull when split needs new slot but inventory is full" do
      definition.update!(max_stack: 8)
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 8)
      end

      # Fill remaining 15 slots
      15.times do |i|
        d = create(:grid_item_definition, slug: "fill-#{i}", name: "Fill #{i}")
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: d)
        end
      end

      # At 16/16 slots, existing stack is full (8/8), grant needs new slot
      expect {
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: definition, quantity: 1)
        end
      }.to raise_error(Grid::InventoryErrors::InventoryFull)
    end

    it "allows stacking up to max_stack" do
      definition.update!(max_stack: 5)
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 3)
      end

      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 2)
      end

      item = hackr.grid_items.find_by(grid_item_definition: definition)
      expect(item.quantity).to eq(5)
    end

    it "does not count installed rig components against capacity" do
      rig = create(:grid_mining_rig, grid_hackr: hackr)
      rig_def = create(:grid_item_definition, :component, slug: "installed-gpu")
      create(:grid_item, grid_item_definition: rig_def, grid_mining_rig: rig,
        grid_hackr: nil, room: nil,
        name: rig_def.name, item_type: rig_def.item_type, rarity: rig_def.rarity,
        properties: rig_def.properties)

      15.times do |i|
        d = create(:grid_item_definition, slug: "fill-#{i}", name: "Fill #{i}")
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: d)
        end
      end

      new_def = create(:grid_item_definition, slug: "last-slot", name: "Last Slot")
      item = nil
      ActiveRecord::Base.transaction do
        item = described_class.grant_item!(hackr: hackr, definition: new_def)
      end
      expect(item).to be_persisted
    end

    it "respects bonus_inventory_slots" do
      hackr.set_stat!("bonus_inventory_slots", 4)

      20.times do |i|
        d = create(:grid_item_definition, slug: "fill-#{i}", name: "Fill #{i}")
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: d)
        end
      end

      new_def = create(:grid_item_definition, slug: "overflow", name: "Overflow")
      expect {
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: new_def)
        end
      }.to raise_error(Grid::InventoryErrors::InventoryFull)
    end

    # Note: transaction_open? check cannot be meaningfully tested because
    # RSpec wraps each example in a transaction (use_transactional_fixtures).
  end

  describe "split grant edge cases" do
    it "splits across multiple new slots when remainder exceeds max_stack" do
      definition.update!(max_stack: 4)
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 4)
      end

      # Grant 5 more: existing full (4/4), creates stack of 4 + stack of 1
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 5)
      end

      items = hackr.grid_items.where(grid_item_definition: definition).order(:id)
      expect(items.count).to eq(3)
      expect(items[0].quantity).to eq(4) # original, unchanged
      expect(items[1].quantity).to eq(4) # new full stack
      expect(items[2].quantity).to eq(1) # remainder
    end

    it "raises InventoryFull mid-split when slots run out" do
      definition.update!(max_stack: 4)

      # Fill 15 slots with other items
      15.times do |i|
        d = create(:grid_item_definition, slug: "fill-#{i}", name: "Fill #{i}")
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: d)
        end
      end

      # 1 slot left. Grant 5 with max_stack 4: first batch (4) takes the last slot,
      # second batch (1) has no slot → InventoryFull, entire transaction rolls back
      expect {
        ActiveRecord::Base.transaction do
          described_class.grant_item!(hackr: hackr, definition: definition, quantity: 5)
        end
      }.to raise_error(Grid::InventoryErrors::InventoryFull)

      # Verify rollback — no items of this definition exist
      expect(hackr.grid_items.where(grid_item_definition: definition).count).to eq(0)
    end

    it "handles nil max_stack as unlimited" do
      definition.update!(max_stack: nil)
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 9999)
      end

      item = hackr.grid_items.find_by(grid_item_definition: definition)
      expect(item.quantity).to eq(9999)
    end

    it "partial fill of existing stack when no new slot needed" do
      definition.update!(max_stack: 10)
      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 7)
      end

      ActiveRecord::Base.transaction do
        described_class.grant_item!(hackr: hackr, definition: definition, quantity: 3)
      end

      item = hackr.grid_items.find_by(grid_item_definition: definition)
      expect(item.quantity).to eq(10)
      expect(hackr.grid_items.where(grid_item_definition: definition).count).to eq(1)
    end
  end
end
