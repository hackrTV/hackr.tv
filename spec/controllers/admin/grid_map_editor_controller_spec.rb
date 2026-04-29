# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::GridMapEditorController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, :admin) }
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:room1) { create(:grid_room, grid_zone: zone, name: "Hub Alpha", room_type: "hub", map_x: 0, map_y: 0) }
  let(:room2) { create(:grid_room, grid_zone: zone, name: "Transit Beta", room_type: "transit", map_x: 1, map_y: 0) }

  before { session[:grid_hackr_id] = admin_hackr.id }

  describe "GET #show" do
    it "returns success" do
      get :show, params: {zone_id: zone.id}
      expect(response).to have_http_status(:ok)
    end

    it "assigns zone and region" do
      get :show, params: {zone_id: zone.id}
      expect(assigns(:zone)).to eq(zone)
      expect(assigns(:region)).to eq(region)
    end
  end

  describe "GET #data" do
    before { room1; room2 }

    it "returns JSON with rooms" do
      get :data, params: {zone_id: zone.id}, format: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["rooms"].length).to eq(2)
    end

    it "includes zone info" do
      get :data, params: {zone_id: zone.id}, format: :json
      json = response.parsed_body
      expect(json["zone"]["id"]).to eq(zone.id)
      expect(json["zone"]["name"]).to eq(zone.name)
    end

    it "includes room positions" do
      get :data, params: {zone_id: zone.id}, format: :json
      json = response.parsed_body
      hub = json["rooms"].find { |r| r["name"] == "Hub Alpha" }
      expect(hub["map_x"]).to eq(0)
      expect(hub["map_y"]).to eq(0)
      expect(hub["position_source"]).to eq("stored")
    end

    it "computes BFS positions for rooms without stored coords" do
      room_no_coords = create(:grid_room, grid_zone: zone, name: "Unplaced Room")
      create(:grid_exit, from_room: room1, to_room: room_no_coords, direction: "east")

      get :data, params: {zone_id: zone.id}, format: :json
      json = response.parsed_body
      unplaced = json["rooms"].find { |r| r["name"] == "Unplaced Room" }
      expect(unplaced["position_source"]).to eq("computed")
    end

    it "includes exits" do
      create(:grid_exit, from_room: room1, to_room: room2, direction: "east")
      get :data, params: {zone_id: zone.id}, format: :json
      json = response.parsed_body
      expect(json["exits"].length).to eq(1)
      expect(json["exits"][0]["direction"]).to eq("east")
    end

    it "includes ghost rooms for cross-zone connections" do
      other_zone = create(:grid_zone, grid_region: region)
      other_room = create(:grid_room, grid_zone: other_zone, name: "Other Zone Room")
      create(:grid_exit, from_room: room1, to_room: other_room, direction: "north")

      get :data, params: {zone_id: zone.id}, format: :json
      json = response.parsed_body
      expect(json["ghost_rooms"].length).to eq(1)
      expect(json["ghost_rooms"][0]["name"]).to eq("Other Zone Room")
    end

    it "includes breach templates" do
      create(:grid_breach_template, published: true)
      get :data, params: {zone_id: zone.id}, format: :json
      json = response.parsed_body
      expect(json["breach_templates"]).not_to be_empty
    end

    it "includes presence counts" do
      hackr = create(:grid_hackr, :online, current_room: room1)
      get :data, params: {zone_id: zone.id}, format: :json
      json = response.parsed_body
      hub = json["rooms"].find { |r| r["id"] == room1.id }
      expect(hub["hackr_count"]).to eq(1)
    end
  end

  describe "POST #create_room" do
    it "creates a room at specified position" do
      expect {
        post :create_room, params: {
          name: "New Room", slug: "new-room", room_type: "transit",
          grid_zone_id: zone.id, map_x: 3, map_y: 2, min_clearance: 0
        }, format: :json
      }.to change(GridRoom, :count).by(1)

      json = response.parsed_body
      expect(json["success"]).to be true
      room = GridRoom.last
      expect(room.map_x).to eq(3)
      expect(room.map_y).to eq(2)
    end

    it "returns errors for invalid room" do
      post :create_room, params: {
        name: "", slug: "", grid_zone_id: zone.id, map_x: 0, map_y: 0, min_clearance: 0
      }, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
      expect(json["errors"]).not_to be_empty
    end
  end

  describe "PATCH #update_room" do
    it "updates room properties" do
      patch :update_room, params: {id: room1.id, name: "Renamed Hub", min_clearance: 5}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(room1.reload.name).to eq("Renamed Hub")
      expect(room1.min_clearance).to eq(5)
    end

    it "updates position" do
      patch :update_room, params: {id: room1.id, map_x: 10, map_y: 5}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(room1.reload.map_x).to eq(10)
      expect(room1.reload.map_y).to eq(5)
    end

    it "returns errors for invalid updates" do
      patch :update_room, params: {id: room1.id, room_type: "nonexistent"}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
    end
  end

  describe "DELETE #destroy_room" do
    it "deletes a room with no dependencies" do
      room = create(:grid_room, grid_zone: zone)
      expect {
        delete :destroy_room, params: {id: room.id}, format: :json
      }.to change(GridRoom, :count).by(-1)

      json = response.parsed_body
      expect(json["success"]).to be true
    end

    it "blocks deletion when hackrs present" do
      create(:grid_hackr, :online, current_room: room1)
      delete :destroy_room, params: {id: room1.id}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
      expect(json["blockers"]).to include(match(/hackr/))
    end

    it "blocks deletion when mobs assigned" do
      create(:grid_mob, grid_room: room1)
      delete :destroy_room, params: {id: room1.id}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
      expect(json["blockers"]).to include(match(/mob/))
    end

    it "blocks deletion when items on floor" do
      definition = create(:grid_item_definition)
      create(:grid_item, grid_item_definition: definition, room: room1)
      delete :destroy_room, params: {id: room1.id}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
      expect(json["blockers"]).to include(match(/item/))
    end

    it "blocks deletion for region special room references" do
      region.update!(hospital_room_id: room1.id)
      delete :destroy_room, params: {id: room1.id}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
      expect(json["blockers"]).to include(match(/hospital/))
    end
  end

  describe "POST #create_exit" do
    it "creates a one-way exit" do
      expect {
        post :create_exit, params: {
          from_room_id: room1.id, to_room_id: room2.id, direction: "east"
        }, format: :json
      }.to change(GridExit, :count).by(1)

      json = response.parsed_body
      expect(json["success"]).to be true
      expect(json["exit"]["direction"]).to eq("east")
    end

    it "creates bidirectional exits" do
      expect {
        post :create_exit, params: {
          from_room_id: room1.id, to_room_id: room2.id,
          direction: "east", bidirectional: true
        }, format: :json
      }.to change(GridExit, :count).by(2)

      json = response.parsed_body
      expect(json["success"]).to be true
      expect(json["reverse_exit"]).not_to be_nil
      expect(json["reverse_exit"]["direction"]).to eq("west")
    end

    it "allows custom reverse direction" do
      post :create_exit, params: {
        from_room_id: room1.id, to_room_id: room2.id,
        direction: "corridor-a", bidirectional: true,
        reverse_direction: "corridor-b"
      }, format: :json
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(json["reverse_exit"]["direction"]).to eq("corridor-b")
    end

    it "returns errors for duplicate direction" do
      create(:grid_exit, from_room: room1, to_room: room2, direction: "east")
      post :create_exit, params: {
        from_room_id: room1.id, to_room_id: room2.id, direction: "east"
      }, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
    end

    it "rolls back both exits if reverse fails" do
      create(:grid_exit, from_room: room2, to_room: room1, direction: "west")
      expect {
        post :create_exit, params: {
          from_room_id: room1.id, to_room_id: room2.id,
          direction: "east", bidirectional: true
        }, format: :json
      }.not_to change(GridExit, :count)
    end
  end

  describe "PATCH #update_exit" do
    it "updates exit direction" do
      exit_record = create(:grid_exit, from_room: room1, to_room: room2, direction: "east")
      patch :update_exit, params: {id: exit_record.id, direction: "northeast"}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(exit_record.reload.direction).to eq("northeast")
    end

    it "updates exit locked state" do
      exit_record = create(:grid_exit, from_room: room1, to_room: room2, direction: "east", locked: false)
      patch :update_exit, params: {id: exit_record.id, locked: true}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(exit_record.reload.locked).to be true
    end

    it "updates exit target room" do
      room3 = create(:grid_room, grid_zone: zone, name: "Room Three")
      exit_record = create(:grid_exit, from_room: room1, to_room: room2, direction: "east")
      patch :update_exit, params: {id: exit_record.id, to_room_id: room3.id}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(exit_record.reload.to_room_id).to eq(room3.id)
    end

    it "returns errors for duplicate direction" do
      create(:grid_exit, from_room: room1, to_room: room2, direction: "north")
      exit_record = create(:grid_exit, from_room: room1, to_room: room2, direction: "east")
      patch :update_exit, params: {id: exit_record.id, direction: "north"}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
    end
  end

  describe "DELETE #destroy_exit" do
    it "deletes a single exit" do
      exit_record = create(:grid_exit, from_room: room1, to_room: room2, direction: "east")
      expect {
        delete :destroy_exit, params: {id: exit_record.id}, format: :json
      }.to change(GridExit, :count).by(-1)
    end

    it "deletes reverse exit when requested" do
      exit1 = create(:grid_exit, from_room: room1, to_room: room2, direction: "east")
      create(:grid_exit, from_room: room2, to_room: room1, direction: "west")
      expect {
        delete :destroy_exit, params: {id: exit1.id, delete_reverse: true}, format: :json
      }.to change(GridExit, :count).by(-2)
    end
  end

  describe "POST #create_mob" do
    it "creates a mob in the room" do
      expect {
        post :create_mob, params: {
          grid_room_id: room1.id, name: "Test NPC", mob_type: "lore"
        }, format: :json
      }.to change(GridMob, :count).by(1)

      json = response.parsed_body
      expect(json["success"]).to be true
      expect(json["mob"]["name"]).to eq("Test NPC")
    end

    it "returns errors for missing name" do
      post :create_mob, params: {grid_room_id: room1.id, name: "", mob_type: "lore"}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
    end
  end

  describe "PATCH #update_mob" do
    it "updates mob name and type" do
      mob = create(:grid_mob, grid_room: room1, name: "Old Name", mob_type: "lore")
      patch :update_mob, params: {id: mob.id, name: "New Name", mob_type: "quest_giver"}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(mob.reload.name).to eq("New Name")
      expect(mob.mob_type).to eq("quest_giver")
    end
  end

  describe "DELETE #remove_mob" do
    it "deletes a mob with no dependencies" do
      mob = create(:grid_mob, grid_room: room1)
      expect {
        delete :remove_mob, params: {id: mob.id}, format: :json
      }.to change(GridMob, :count).by(-1)
    end

    it "blocks deletion when shop listings exist" do
      mob = create(:grid_mob, grid_room: room1, mob_type: "vendor")
      definition = create(:grid_item_definition)
      create(:grid_shop_listing, grid_mob: mob, grid_item_definition: definition)
      delete :remove_mob, params: {id: mob.id}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
      expect(json["blockers"]).to include(match(/shop listing/))
    end
  end

  describe "POST #create_encounter" do
    it "places a breach encounter in a room" do
      template = create(:grid_breach_template, published: true)
      expect {
        post :create_encounter, params: {
          grid_room_id: room1.id, grid_breach_template_id: template.id
        }, format: :json
      }.to change(GridBreachEncounter, :count).by(1)

      json = response.parsed_body
      expect(json["success"]).to be true
      expect(json["encounter"]["template_name"]).to eq(template.name)
    end

    it "rejects duplicate template in same room" do
      template = create(:grid_breach_template, published: true)
      create(:grid_breach_encounter, grid_room: room1, grid_breach_template: template)
      post :create_encounter, params: {
        grid_room_id: room1.id, grid_breach_template_id: template.id
      }, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
    end
  end

  describe "DELETE #destroy_encounter" do
    it "removes an encounter" do
      template = create(:grid_breach_template, published: true)
      encounter = create(:grid_breach_encounter, grid_room: room1, grid_breach_template: template)
      expect {
        delete :destroy_encounter, params: {id: encounter.id}, format: :json
      }.to change(GridBreachEncounter, :count).by(-1)
    end

    it "blocks removal when active breaches exist" do
      template = create(:grid_breach_template, published: true)
      encounter = create(:grid_breach_encounter, grid_room: room1, grid_breach_template: template)
      hackr = create(:grid_hackr, :online, current_room: room1)
      create(:grid_hackr_breach, grid_hackr: hackr, grid_breach_template: template,
             grid_breach_encounter: encounter, state: "active")

      delete :destroy_encounter, params: {id: encounter.id}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be false
    end
  end

  describe "POST #auto_layout" do
    it "computes and saves BFS positions" do
      room_a = create(:grid_room, grid_zone: zone, name: "A", map_x: nil, map_y: nil, room_type: "hub")
      room_b = create(:grid_room, grid_zone: zone, name: "B", map_x: nil, map_y: nil)
      create(:grid_exit, from_room: room_a, to_room: room_b, direction: "east")

      post :auto_layout, params: {zone_id: zone.id}, format: :json
      json = response.parsed_body
      expect(json["success"]).to be true
      expect(json["updated"]).to eq(2)

      room_a.reload
      room_b.reload
      expect(room_a.map_x).not_to be_nil
      expect(room_b.map_x).not_to be_nil
      expect(room_b.map_x).to eq(room_a.map_x + 1) # east = +1 x
    end
  end

  describe "authentication" do
    it "requires admin" do
      session[:grid_hackr_id] = nil
      get :show, params: {zone_id: zone.id}
      expect(response).to have_http_status(:redirect)
    end

    it "rejects non-admin users" do
      regular = create(:grid_hackr, role: "operative")
      session[:grid_hackr_id] = regular.id
      get :show, params: {zone_id: zone.id}
      expect(response).to have_http_status(:redirect)
    end
  end
end
