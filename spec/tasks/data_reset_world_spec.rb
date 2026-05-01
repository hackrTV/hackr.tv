require "rails_helper"
require "rake"

RSpec.describe "data:reset_world" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("data:reset_world")
  end

  before do
    Rake::Task["data:reset_world"].reenable
    Rake::Task["data:economy"].reenable
    allow($stdin).to receive(:gets).and_return("RESET WORLD\n")
  end

  # Rig component definitions required by data:economy provisioning
  %w[basic-motherboard basic-psu basic-cpu basic-gpu basic-ram].each do |slug|
    let!(slug.underscore.to_sym) { create(:grid_item_definition, :component, slug: slug, name: slug.titleize) }
  end

  let!(:region) { create(:grid_region) }
  let!(:faction) { create(:grid_faction) }

  # --- PAC data (should survive) ---
  let!(:pac_zone) do
    create(:grid_zone, slug: "#{region.slug}-govcorp-pac", grid_region: region, grid_faction: faction)
  end
  let!(:pac_room_a) { create(:grid_room, grid_zone: pac_zone) }
  let!(:pac_room_b) { create(:grid_room, grid_zone: pac_zone) }
  let!(:pac_exit) { create(:grid_exit, from_room: pac_room_a, to_room: pac_room_b, direction: "north") }
  let!(:pac_mob) { create(:grid_mob, grid_room: pac_room_a) }
  let!(:pac_encounter) { create(:grid_breach_encounter, grid_room: pac_room_a) }

  # --- Non-PAC data (should be deleted) ---
  let!(:zone) { create(:grid_zone, grid_region: region) }
  let!(:room_a) { create(:grid_room, grid_zone: zone) }
  let!(:room_b) { create(:grid_room, grid_zone: zone) }
  let!(:exit_record) { create(:grid_exit, from_room: room_a, to_room: room_b, direction: "east") }
  let!(:cross_exit) { create(:grid_exit, from_room: pac_room_b, to_room: room_a, direction: "south") }
  let!(:mob) { create(:grid_mob, :quest_giver, grid_room: room_a) }
  let!(:vendor) { create(:grid_mob, :vendor, grid_room: room_b) }
  let!(:encounter) { create(:grid_breach_encounter, grid_room: room_a) }
  let!(:shop_listing) { create(:grid_shop_listing, grid_mob: vendor) }
  let!(:mission) { create(:grid_mission, giver_mob: mob) }
  let!(:mission_objective) { create(:grid_mission_objective, grid_mission: mission) }

  # --- Hackr with progression (account preserved, data wiped) ---
  let!(:hackr) do
    create(:grid_hackr, current_room_id: room_a.id, zone_entry_room_id: room_a.id)
  end
  let!(:item) { create(:grid_item, :in_inventory, grid_hackr: hackr) }
  let!(:breach) { create(:grid_hackr_breach, grid_hackr: hackr) }
  let!(:hackr_mission) { create(:grid_hackr_mission, grid_hackr: hackr, grid_mission: mission) }
  let!(:hackr_achievement) { create(:grid_hackr_achievement, grid_hackr: hackr) }
  let!(:message) { create(:grid_message, grid_hackr: hackr, room: room_a) }
  let!(:impound) { create(:grid_impound_record, grid_hackr: hackr) }

  it "preserves PAC + regions, deletes non-PAC world + player data, re-provisions economy" do
    Rake::Task["data:reset_world"].invoke

    # --- Regions preserved ---
    expect(GridRegion.find_by(id: region.id)).to be_present

    # --- PAC preserved ---
    expect(GridZone.find_by(id: pac_zone.id)).to be_present
    expect(GridRoom.where(grid_zone_id: pac_zone.id).count).to eq(2)
    expect(GridExit.find_by(id: pac_exit.id)).to be_present
    expect(GridMob.find_by(id: pac_mob.id)).to be_present
    expect(GridBreachEncounter.find_by(id: pac_encounter.id)).to be_present

    # --- Non-PAC geography deleted ---
    expect(GridZone.find_by(id: zone.id)).to be_nil
    expect(GridRoom.find_by(id: room_a.id)).to be_nil
    expect(GridRoom.find_by(id: room_b.id)).to be_nil
    expect(GridExit.find_by(id: exit_record.id)).to be_nil

    # --- Cross-zone exit deleted ---
    expect(GridExit.find_by(id: cross_exit.id)).to be_nil

    # --- Non-PAC content deleted ---
    expect(GridMob.find_by(id: mob.id)).to be_nil
    expect(GridMob.find_by(id: vendor.id)).to be_nil
    expect(GridBreachEncounter.find_by(id: encounter.id)).to be_nil
    expect(GridShopListing.count).to eq(0)
    expect(GridMission.count).to eq(0)
    expect(GridMissionObjective.count).to eq(0)

    # --- Player data deleted ---
    expect(GridItem.where(grid_hackr_id: hackr.id).count).to eq(0)
    expect(GridHackrBreach.count).to eq(0)
    expect(GridHackrMission.count).to eq(0)
    expect(GridHackrAchievement.count).to eq(0)
    expect(GridMessage.count).to eq(0)
    expect(GridImpoundRecord.count).to eq(0)

    # --- Hackr account preserved, stats reset ---
    hackr.reload
    expect(hackr).to be_present
    expect(hackr.current_room_id).to be_nil
    expect(hackr.zone_entry_room_id).to be_nil
    expect(hackr.stats).to eq({})

    # --- Economy re-provisioned ---
    expect(GridCache.where(system_type: "genesis")).to exist
    expect(hackr.grid_caches.count).to be >= 1
    expect(hackr.grid_mining_rig).to be_present
  end

  it "aborts without changes when confirmation is wrong" do
    allow($stdin).to receive(:gets).and_return("no\n")

    Rake::Task["data:reset_world"].invoke

    expect(GridZone.find_by(id: zone.id)).to be_present
    expect(GridRoom.find_by(id: room_a.id)).to be_present
    expect(hackr.reload.current_room_id).to eq(room_a.id)
  end
end
