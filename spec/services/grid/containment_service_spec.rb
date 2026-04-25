# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::ContainmentService do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:facility_zone) { create(:grid_zone, grid_region: region) }
  let(:containment_room) { create(:grid_room, grid_zone: facility_zone, room_type: "containment") }
  let(:corridor) { create(:grid_room, grid_zone: facility_zone, room_type: "govcorp") }
  let(:impound_room) { create(:grid_room, grid_zone: facility_zone, room_type: "impound") }
  let(:exit_room) { create(:grid_room, grid_zone: zone) }
  let(:bribe_exit_room) { create(:grid_room, grid_zone: zone) }
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
    region.update!(
      containment_room: containment_room,
      facility_exit_room: exit_room,
      facility_bribe_exit_room: bribe_exit_room
    )
  end

  describe ".capture!" do
    it "teleports hackr to containment room" do
      result = described_class.capture!(hackr: hackr, breach: breach)

      expect(result.containment_room).to eq(containment_room)
      expect(hackr.reload.current_room).to eq(containment_room)
      expect(hackr.stat("captured")).to eq(true)
      expect(hackr.stat("captured_origin_room_id")).to eq(room.id)
      expect(hackr.stat("facility_alert_level")).to eq(0)
    end

    it "raises AlreadyCaptured when already captured" do
      described_class.capture!(hackr: hackr, breach: breach)
      expect {
        described_class.capture!(hackr: hackr, breach: breach)
      }.to raise_error(Grid::ContainmentService::AlreadyCaptured)
    end

    context "with impound" do
      let(:deck_def) do
        create(:grid_item_definition, :gear,
          slug: "cap-deck-#{SecureRandom.hex(4)}", name: "Test Deck", value: 1000,
          properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
      end

      let!(:deck) do
        item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
        item.update!(equipped_slot: "deck")
        item
      end

      it "impounds gear when impound: true" do
        result = described_class.capture!(hackr: hackr, breach: breach, impound: true)

        expect(result.impound_result).to be_present
        expect(result.impound_result.items_seized).not_to be_empty
        expect(hackr.grid_impound_records.impounded.count).to eq(1)
      end

      it "skips impound when impound: false" do
        result = described_class.capture!(hackr: hackr, breach: breach, impound: false)

        expect(result.impound_result).to be_nil
        expect(hackr.grid_impound_records.count).to eq(0)
      end
    end
  end

  describe ".alert_increment!" do
    before { described_class.capture!(hackr: hackr, breach: breach) }

    it "increments alert level on room move" do
      hackr.update!(current_room: corridor)
      result = described_class.alert_increment!(hackr: hackr)

      expect(result.alert_level).to eq(described_class::ALERT_PER_MOVE)
      expect(result.caught).to be false
    end

    it "does not increment in safe rooms" do
      hackr.update!(current_room: impound_room)
      result = described_class.alert_increment!(hackr: hackr)

      expect(result.alert_level).to eq(0)
      expect(result.caught).to be false
    end

    it "catches hackr when threshold reached" do
      hackr.set_stat!("facility_alert_level", described_class::ALERT_THRESHOLD - described_class::ALERT_PER_MOVE)
      hackr.update!(current_room: corridor)
      result = described_class.alert_increment!(hackr: hackr)

      expect(result.caught).to be true
      expect(hackr.reload.current_room).to eq(containment_room)
      expect(hackr.stat("facility_alert_level")).to eq(0)
    end
  end

  describe ".alert_reduce!" do
    before do
      described_class.capture!(hackr: hackr, breach: breach)
      hackr.set_stat!("facility_alert_level", 50)
    end

    it "reduces alert level" do
      described_class.alert_reduce!(hackr: hackr, amount: 25)
      expect(hackr.stat("facility_alert_level")).to eq(25)
    end

    it "clamps at zero" do
      described_class.alert_reduce!(hackr: hackr, amount: 100)
      expect(hackr.stat("facility_alert_level")).to eq(0)
    end
  end

  describe ".escape_facility!" do
    before { described_class.capture!(hackr: hackr, breach: breach) }

    it "clears captured state and teleports to exit room" do
      result = described_class.escape_facility!(hackr: hackr, via: :sally_port)

      expect(result.destination_room).to eq(exit_room)
      expect(hackr.reload.current_room).to eq(exit_room)
      expect(hackr.stat("captured")).to be_nil
      expect(hackr.stat("facility_alert_level")).to be_nil
    end

    it "uses bribe exit room for bribe path" do
      result = described_class.escape_facility!(hackr: hackr, via: :bribe)
      expect(result.destination_room).to eq(bribe_exit_room)
    end
  end

  describe ".bribe_exit!" do
    before do
      described_class.capture!(hackr: hackr, breach: breach)
      fund_cache(cache, 50_000)
    end

    it "pays fee and exits facility" do
      result = described_class.bribe_exit!(hackr: hackr)

      expect(result.fee_paid).to be > 0
      expect(hackr.reload.stat("captured")).to be_nil
      expect(hackr.current_room).to eq(bribe_exit_room)
    end

    it "forfeits impounded gear" do
      # Equip and impound gear first
      deck_def = create(:grid_item_definition, :gear,
        slug: "bribe-deck-#{SecureRandom.hex(4)}", name: "Bribe Deck", value: 500,
        properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
      deck = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
      deck.update!(equipped_slot: "deck")
      Grid::ImpoundService.impound_gear!(hackr: hackr, breach: breach)

      result = described_class.bribe_exit!(hackr: hackr)

      expect(result.forfeit_results.size).to eq(1)
      expect(hackr.grid_impound_records.forfeited.count).to eq(1)
    end

    it "raises InsufficientFunds when hackr can't afford" do
      poor_hackr = create(:grid_hackr, current_room: room)
      create(:grid_cache, :default, grid_hackr: poor_hackr)
      poor_breach = create(:grid_hackr_breach, grid_hackr: poor_hackr, grid_breach_template: template)
      described_class.capture!(hackr: poor_hackr, breach: poor_breach)

      expect {
        described_class.bribe_exit!(hackr: poor_hackr)
      }.to raise_error(Grid::ContainmentService::InsufficientFunds)
    end
  end

  describe ".captured?" do
    it "returns true when captured" do
      hackr.set_stat!("captured", true)
      expect(described_class.captured?(hackr)).to be true
    end

    it "returns false when not captured" do
      expect(described_class.captured?(hackr)).to be false
    end
  end

  describe ".compute_exit_bribe" do
    it "calculates bribe from constants" do
      hackr.set_stat!("clearance", 50)
      cost = described_class.compute_exit_bribe(hackr)
      # 250 + 50*15 = 1000
      expect(cost).to eq(1000)
    end
  end

  describe ".render_alert_bar" do
    it "renders green at low alert" do
      bar = described_class.render_alert_bar(20)
      expect(bar).to include("FACILITY ALERT")
      expect(bar).to include("#34d399") # green
    end

    it "renders amber at medium alert" do
      bar = described_class.render_alert_bar(50)
      expect(bar).to include("#fbbf24") # amber
    end

    it "renders red at high alert" do
      bar = described_class.render_alert_bar(80)
      expect(bar).to include("#f87171") # red
    end
  end
end
