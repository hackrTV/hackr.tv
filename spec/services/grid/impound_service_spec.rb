# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::ImpoundService do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:template) { create(:grid_breach_template) }
  let(:breach) { create(:grid_hackr_breach, grid_hackr: hackr, grid_breach_template: template) }

  let(:cache) { create(:grid_cache, :default, grid_hackr: hackr) }
  let(:gameplay_pool) { create(:grid_cache, :gameplay_pool) }
  let(:burn_cache) { create(:grid_cache, :burn) }

  def fund_cache(target_cache, amount)
    source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: source, to_cache: target_cache, amount: amount,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  before do
    cache
    gameplay_pool
    burn_cache
  end

  let(:deck_def) do
    create(:grid_item_definition, :gear,
      slug: "impound-test-deck-#{SecureRandom.hex(4)}",
      name: "Test Deck",
      value: 2000,
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
  end

  let(:chest_def) do
    create(:grid_item_definition, :gear,
      slug: "impound-test-chest-#{SecureRandom.hex(4)}",
      name: "Test Chestplate",
      value: 1500,
      properties: {"slot" => "chest", "effects" => {"bonus_max_health" => 20}})
  end

  let(:software_def) do
    create(:grid_item_definition,
      slug: "impound-test-sw-#{SecureRandom.hex(4)}",
      name: "Test Program",
      item_type: "software",
      properties: {"software_category" => "offensive", "slot_cost" => 1, "battery_cost" => 8})
  end

  let!(:deck) do
    item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    item.update!(equipped_slot: "deck")
    item
  end

  let!(:chest) do
    item = create(:grid_item, :in_inventory, grid_item_definition: chest_def, grid_hackr: hackr)
    item.update!(equipped_slot: "chest")
    item
  end

  let!(:software) do
    create(:grid_item, grid_item_definition: software_def,
      grid_hackr: hackr, room: nil, deck_id: deck.id,
      item_type: "software", name: "Test Program")
  end

  describe ".compute_bribe" do
    it "calculates bribe from constants" do
      hackr.set_stat!("clearance", 20)
      items = [deck, chest]
      cost = described_class.compute_bribe(hackr: hackr, items: items)
      # 500 + 20*25 + (2000+1500)*0.10 = 500 + 500 + 350 = 1350
      expect(cost).to eq(1350)
    end

    it "handles zero clearance" do
      hackr.set_stat!("clearance", 0)
      cost = described_class.compute_bribe(hackr: hackr, items: [deck])
      # 500 + 0 + 2000*0.10 = 700
      expect(cost).to eq(700)
    end
  end

  describe ".impound_gear!" do
    it "confiscates all equipped items" do
      result = described_class.impound_gear!(hackr: hackr, breach: breach)

      expect(result.impound_record).to be_a(GridImpoundRecord)
      expect(result.impound_record.status).to eq("impounded")
      expect(result.items_seized.map(&:name)).to contain_exactly("Test Deck", "Test Chestplate")
      expect(result.bribe_cost).to be > 0
      expect(result.display).to include("GEAR CONFISCATED")
    end

    it "sets impound FK on seized items" do
      result = described_class.impound_gear!(hackr: hackr, breach: breach)
      record = result.impound_record

      deck.reload
      chest.reload
      expect(deck.grid_impound_record_id).to eq(record.id)
      expect(chest.grid_impound_record_id).to eq(record.id)
      expect(deck.equipped_slot).to be_nil
      expect(chest.equipped_slot).to be_nil
    end

    it "impounds software loaded in DECK" do
      result = described_class.impound_gear!(hackr: hackr, breach: breach)

      software.reload
      expect(software.grid_impound_record_id).to eq(result.impound_record.id)
    end

    it "excludes impounded items from equipped_by scope" do
      described_class.impound_gear!(hackr: hackr, breach: breach)

      expect(GridItem.equipped_by(hackr)).to be_empty
    end

    it "excludes impounded items from in_inventory scope" do
      described_class.impound_gear!(hackr: hackr, breach: breach)

      inventory_ids = GridItem.in_inventory(hackr).pluck(:id)
      expect(inventory_ids).not_to include(deck.id, chest.id)
    end

    it "clears loadout effects" do
      described_class.impound_gear!(hackr: hackr, breach: breach)
      hackr.reset_loadout_cache!

      expect(hackr.loadout_effects).to eq(Hash.new(0))
    end

    it "clamps vitals to new effective max" do
      hackr.set_stat!("health", 120) # Over base 100, boosted by chest gear
      described_class.impound_gear!(hackr: hackr, breach: breach)

      expect(hackr.stat("health")).to be <= 100
    end

    it "raises NoEquippedGear when nothing equipped" do
      deck.update!(equipped_slot: nil)
      chest.update!(equipped_slot: nil)

      expect {
        described_class.impound_gear!(hackr: hackr, breach: breach)
      }.to raise_error(Grid::ImpoundService::NoEquippedGear)
    end

    it "freezes bribe cost at capture time" do
      result = described_class.impound_gear!(hackr: hackr, breach: breach)
      expect(result.impound_record.bribe_cost).to eq(result.bribe_cost)
    end
  end

  describe ".recover_gear!" do
    let!(:impound_result) { described_class.impound_gear!(hackr: hackr, breach: breach) }
    let(:record) { impound_result.impound_record }

    before do
      fund_cache(cache, 50_000)
    end

    it "returns items to inventory" do
      result = described_class.recover_gear!(hackr: hackr, impound_record: record)

      expect(result.items_returned).not_to be_empty
      expect(result.impound_record.status).to eq("recovered")
      expect(result.display).to include("GEAR RECOVERED")
    end

    it "clears impound FK on items" do
      described_class.recover_gear!(hackr: hackr, impound_record: record)

      deck.reload
      chest.reload
      software.reload
      expect(deck.grid_impound_record_id).to be_nil
      expect(chest.grid_impound_record_id).to be_nil
      expect(software.grid_impound_record_id).to be_nil
    end

    it "items appear in inventory after recovery" do
      described_class.recover_gear!(hackr: hackr, impound_record: record)

      inventory_names = GridItem.in_inventory(hackr).pluck(:name)
      expect(inventory_names).to include("Test Deck", "Test Chestplate")
    end

    it "items are unequipped after recovery" do
      described_class.recover_gear!(hackr: hackr, impound_record: record)

      deck.reload
      expect(deck.equipped_slot).to be_nil
    end

    it "software stays loaded in DECK after recovery" do
      described_class.recover_gear!(hackr: hackr, impound_record: record)

      software.reload
      expect(software.deck_id).to eq(deck.id)
    end

    it "raises InsufficientBalance when hackr can't afford bribe" do
      # Don't fund the cache — leave it empty
      poor_hackr = create(:grid_hackr, current_room: room)
      create(:grid_cache, :default, grid_hackr: poor_hackr)
      poor_deck_def = create(:grid_item_definition, :gear,
        slug: "poor-deck-#{SecureRandom.hex(4)}", name: "Poor Deck", value: 100,
        properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
      poor_deck = create(:grid_item, :in_inventory, grid_item_definition: poor_deck_def, grid_hackr: poor_hackr)
      poor_deck.update!(equipped_slot: "deck")
      poor_breach = create(:grid_hackr_breach, grid_hackr: poor_hackr, grid_breach_template: template)
      poor_result = described_class.impound_gear!(hackr: poor_hackr, breach: poor_breach)

      expect {
        described_class.recover_gear!(hackr: poor_hackr, impound_record: poor_result.impound_record)
      }.to raise_error(Grid::ImpoundService::InsufficientBalance)
    end

    it "raises RecordNotImpounded for already-recovered record" do
      described_class.recover_gear!(hackr: hackr, impound_record: record)

      expect {
        described_class.recover_gear!(hackr: hackr, impound_record: record)
      }.to raise_error(Grid::ImpoundService::RecordNotImpounded)
    end

    it "raises NotOwner for another hackr's record" do
      other_hackr = create(:grid_hackr)
      expect {
        described_class.recover_gear!(hackr: other_hackr, impound_record: record)
      }.to raise_error(Grid::ImpoundService::NotOwner)
    end
  end

  describe ".forfeit!" do
    let!(:impound_result) { described_class.impound_gear!(hackr: hackr, breach: breach) }
    let(:record) { impound_result.impound_record }

    it "permanently destroys impounded items" do
      item_ids = record.impounded_items.pluck(:id)
      result = described_class.forfeit!(impound_record: record)

      expect(result.impound_record.status).to eq("forfeited")
      expect(result.items_destroyed).to be > 0
      expect(GridItem.where(id: item_ids)).to be_empty
      expect(result.display).to include("IMPOUND FORFEITED")
    end

    it "raises RecordNotImpounded for already-forfeited record" do
      described_class.forfeit!(impound_record: record)

      expect {
        described_class.forfeit!(impound_record: record)
      }.to raise_error(Grid::ImpoundService::RecordNotImpounded)
    end
  end

  describe "multiple impound sets" do
    it "tracks separate capture events independently" do
      result1 = described_class.impound_gear!(hackr: hackr, breach: breach)

      # Mark first breach as completed so unique index allows a new active breach
      breach.update!(state: "failure", ended_at: Time.current)

      # Hackr gets new gear and gets captured again
      new_deck_def = create(:grid_item_definition, :gear,
        slug: "impound-deck2-#{SecureRandom.hex(4)}", name: "Second Deck", value: 3000,
        properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
      new_deck = create(:grid_item, :in_inventory, grid_item_definition: new_deck_def, grid_hackr: hackr)
      new_deck.update!(equipped_slot: "deck")

      breach2 = create(:grid_hackr_breach, grid_hackr: hackr, grid_breach_template: template)
      result2 = described_class.impound_gear!(hackr: hackr, breach: breach2)

      expect(result1.impound_record.id).not_to eq(result2.impound_record.id)
      expect(hackr.grid_impound_records.impounded.count).to eq(2)
    end
  end
end
