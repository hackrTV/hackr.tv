# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::GridController, type: :controller do
  describe "GET #loadout_index" do
    context "with no logged-in hackr" do
      it "returns 401 unauthorized" do
        get :loadout_index, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "returns the expected JSON shape with empty loadout" do
        get :loadout_index, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json).to have_key("slots")
        expect(json).to have_key("inventory_gear")
        expect(json).to have_key("active_effects")
        expect(json).to have_key("vitals")

        expect(json["slots"].length).to eq(13)
        expect(json["slots"].map { |s| s["slot"] }).to eq(GridItem::GEAR_SLOTS)
        json["slots"].each do |slot|
          expect(slot).to have_key("slot")
          expect(slot).to have_key("label")
          expect(slot).to have_key("item")
          expect(slot["item"]).to be_nil
        end

        expect(json["inventory_gear"]).to eq([])
        expect(json["active_effects"]).to eq({})

        %w[health energy psyche].each do |vital|
          expect(json["vitals"][vital]).to eq({"current" => 100, "max" => 100})
        end
      end

      it "returns equipped items in their slots" do
        gear_def = create(:grid_item_definition, :gear, name: "Test Helm",
          properties: {"slot" => "head", "effects" => {"bonus_max_health" => 15}})
        gear = create(:grid_item, :in_inventory, grid_item_definition: gear_def, grid_hackr: hackr)
        gear.update!(equipped_slot: "head")

        get :loadout_index, format: :json
        json = JSON.parse(response.body)

        head_slot = json["slots"].find { |s| s["slot"] == "head" }
        expect(head_slot["item"]).not_to be_nil
        expect(head_slot["item"]["name"]).to eq("Test Helm")
        expect(head_slot["item"]["effects"]).to eq({"bonus_max_health" => 15})
        expect(head_slot["item"]["equipped_slot"]).to eq("head")

        expect(json["active_effects"]).to eq({"bonus_max_health" => 15.0})
        expect(json["vitals"]["health"]["max"]).to eq(115)
      end

      it "returns unequipped gear in inventory_gear" do
        gear_def = create(:grid_item_definition, :gear, name: "Spare Visor",
          properties: {"slot" => "eyes", "effects" => {}})
        create(:grid_item, :in_inventory, grid_item_definition: gear_def, grid_hackr: hackr)

        get :loadout_index, format: :json
        json = JSON.parse(response.body)

        expect(json["inventory_gear"].length).to eq(1)
        expect(json["inventory_gear"].first["name"]).to eq("Spare Visor")
        expect(json["inventory_gear"].first["gear_slot"]).to eq("eyes")
      end
    end
  end
end
