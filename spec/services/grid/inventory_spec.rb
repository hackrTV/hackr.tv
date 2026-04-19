require "rails_helper"

RSpec.describe Grid::Inventory do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:definition) { create(:grid_item_definition, slug: "test-item", name: "Test Item") }

  describe ".grant_item!" do
    context "when hackr has no existing item" do
      it "creates a new item" do
        expect {
          described_class.grant_item!(hackr: hackr, definition: definition, quantity: 3)
        }.to change { hackr.grid_items.count }.by(1)

        item = hackr.grid_items.find_by(grid_item_definition: definition)
        expect(item.name).to eq("Test Item")
        expect(item.quantity).to eq(3)
      end
    end

    context "when hackr already has the item" do
      let!(:existing) do
        GridItem.create!(definition.item_attributes.merge(grid_hackr: hackr, quantity: 2))
      end

      it "stacks into existing item" do
        expect {
          described_class.grant_item!(hackr: hackr, definition: definition, quantity: 5)
        }.not_to change { hackr.grid_items.count }

        expect(existing.reload.quantity).to eq(7)
      end
    end

    context "with default quantity" do
      it "grants 1 by default" do
        described_class.grant_item!(hackr: hackr, definition: definition)
        item = hackr.grid_items.find_by(grid_item_definition: definition)
        expect(item.quantity).to eq(1)
      end
    end

    context "transaction guard" do
      it "raises if called outside a transaction" do
        # RSpec's use_transactional_fixtures wraps each example in a
        # transaction, so we need to explicitly test without one.
        # Temporarily stub transaction_open? to simulate no transaction.
        allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)

        expect {
          described_class.grant_item!(hackr: hackr, definition: definition)
        }.to raise_error(RuntimeError, /must be called inside a transaction/)
      end
    end
  end
end
