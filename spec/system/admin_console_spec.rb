require "rails_helper"

# The /root console in a real browser (console-ui-for-all-admin), only
# where a request spec cannot see the behavior.
RSpec.describe "Admin console", type: :system do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:target) { create(:grid_hackr, hackr_alias: "ghostline") }

  def log_in!
    visit "/grid/login"
    fill_in "hackr_alias", with: admin.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  # Phase 2: one ISSUE form, two actions — the layout's confirm handler
  # reads the clicked button's own data-confirm before the form's first.
  it "confirms [BLACKOUT] and [SQUELCH] with their own messages" do
    log_in!
    visit "/root/uplink/punishments"
    fill_in "punishment-username", with: "ghostline"

    dismiss_confirm("Black out this hackr? They lose the Uplink entirely.") { click_button "[BLACKOUT]" }
    expect(page).to have_current_path("/root/uplink/punishments")
    expect(UserPunishment.count).to eq(0)

    accept_confirm("Squelch this hackr? They keep reading the Uplink but cannot send.") { click_button "[SQUELCH]" }
    expect(page).to have_content("ghostline has been squelched permanently.")
    expect(UserPunishment.squelched?(target)).to be(true)
    expect(UserPunishment.blackedout?(target)).to be(false)
  end

  # Phase 3: the mob record's editors are inline JS retargeted onto the
  # console (ids kept, rows built as .rc-topic / .rc-btn) — the tree and
  # the vendor config still serialize into the hidden fields on save.
  it "builds a dialogue tree and a vendor config in the mob editors and saves them" do
    mob = create(:grid_mob, name: "Dockhand", dialogue_tree: {"greeting" => "Hey."})
    log_in!
    visit "/root/grid_mobs/#{mob.id}/edit"

    expect(page).to have_field("dialogue-greeting", with: "Hey.")
    click_button "[+] ADD TOPIC"
    within(".rc-topic") do
      find(".dialogue-key").fill_in(with: "job")
      find(".dialogue-response").fill_in(with: "Lift crates.")
      click_button "[+] SUB"
      within(".rc-topic-children .rc-topic") do
        find(".dialogue-key").fill_in(with: "pay")
        find(".dialogue-response").fill_in(with: "Ten CRED.")
      end
    end

    select "Black Market", from: "vendor-shop-type"
    expect(page).to have_field("vendor-rotation-count")
    fill_in "vendor-rotation-count", with: "5"

    click_button "[RAW JSON]", match: :first
    expect(find("#dialogue-raw-textarea").value).to include('"pay"')
    click_button "[STRUCTURED]", match: :first

    click_button "[SAVE MOB]"
    expect(page).to have_content("Mob 'Dockhand' updated.")
    expect(mob.reload.dialogue_tree).to eq(
      "greeting" => "Hey.",
      "topics" => {"job" => {"response" => "Lift crates.", "topics" => {"pay" => {"response" => "Ten CRED."}}}}
    )
    expect(mob.vendor_config).to eq("shop_type" => "black_market", "restock_interval_hours" => 24, "rotation_count" => 5)
  end

  # A save from RAW JSON mode parses the textarea first: malformed JSON
  # stops the submit with the error under it, the edit still in the box.
  it "refuses to save a mob while a raw JSON editor holds malformed JSON" do
    mob = create(:grid_mob, name: "Dockhand", dialogue_tree: {"greeting" => "Hey."})
    log_in!
    visit "/root/grid_mobs/#{mob.id}/edit"

    click_button "[RAW JSON]", match: :first
    find("#dialogue-raw-textarea").fill_in(with: '{"greeting": "Yo",}')
    click_button "[SAVE MOB]"

    expect(page).to have_css("#dialogue-raw-error", text: "Invalid JSON")
    expect(find("#dialogue-raw-textarea").value).to eq('{"greeting": "Yo",}')
    expect(page).to have_no_content("Mob 'Dockhand' updated.")
    expect(mob.reload.dialogue_tree).to eq("greeting" => "Hey.")

    find("#dialogue-raw-textarea").fill_in(with: '{"greeting": "Yo"}')
    click_button "[SAVE MOB]"
    expect(page).to have_content("Mob 'Dockhand' updated.")
    expect(mob.reload.dialogue_tree).to eq("greeting" => "Yo")
  end

  # Phase 4: the salvage yield rows are inline JS retargeted onto ledger
  # rows (ids kept) — a cloned row submits under its fresh index, a saved
  # row's [x] flags _destroy (the schematic ingredients run the same code).
  it "adds and removes salvage yield rows on the item record and saves them" do
    item = create(:grid_item_definition, name: "Flux GPU", slug: "flux-gpu")
    old_output = create(:grid_item_definition, name: "Copper Wire")
    new_output = create(:grid_item_definition, name: "Scrap Metal")
    saved = create(:grid_salvage_yield, source_definition: item, output_definition: old_output)
    log_in!
    visit "/root/grid_item_definitions/flux-gpu/edit"

    within("#salvage-yields-table") { first(".yield-destroy-btn").click }
    expect(page).to have_css("#salvage-yields-table .rc-row:not(.rc-row--head)", count: 1)
    click_button "[+] ADD YIELD"
    within(all("#salvage-yields-table .rc-row:not(.rc-row--head)").last) do
      find("select").select("Scrap Metal [COMMON]")
      find("input[name$='[quantity]']").fill_in(with: "4")
    end

    click_button "[SAVE ITEM]"
    expect(page).to have_content("Definition 'Flux GPU' updated.")
    expect(GridSalvageYield.exists?(saved.id)).to be(false)
    expect(item.salvage_yields.reload.map { |y| [y.output_definition_id, y.quantity] }).to eq([[new_output.id, 4]])
  end

  # Phase 4: the mission wizard's steps are client-side (hidden sections,
  # rows built by its script). A rejected create comes back filled in;
  # the created mission's record drops a saved reward row with [x] (the
  # old inline onclick handlers never ran under the CSP).
  it "walks the mission wizard, recovers a rejected create, and removes a saved reward on the record" do
    create(:grid_mob, :quest_giver, name: "AXIOM")
    create(:grid_mission, slug: "first-signal")
    log_in!
    visit "/root/grid_mission_wizard/new"

    expect(page).to have_css("#step-1:not([hidden])")
    click_button "[>] NEXT"
    fill_in "mob-select-input", with: "AXIOM"
    find(".admin-combobox-option", text: "AXIOM").click
    click_button "[>] NEXT"
    expect(page).to have_css("#step-4:not([hidden])")
    expect(page).to have_css(".step-dot.skipped[data-step='3']")
    fill_in "mission-name", with: "First Signal"
    expect(page).to have_field("mission-slug", with: "first-signal")
    click_button "[>] NEXT"

    within("#objectives-tbody") do
      find("select").select("visit_room")
      find("input[name$='[label]']").fill_in(with: "Find the drop")
    end
    click_button "[+] ADD OBJECTIVE"
    expect(page).to have_css("#objectives-tbody .rc-row", count: 2)
    all("#objectives-tbody [data-row-remove]").last.click
    expect(page).to have_css("#objectives-tbody .rc-row", count: 1)
    click_button "[>] NEXT"
    within("#rewards-tbody") { find("input[name$='[amount]']").fill_in(with: "30") }
    click_button "[>] NEXT"
    within("#review-content") { expect(page).to have_content("First Signal").and have_content("visit_room: Find the drop") }

    click_button "[CREATE MISSION]"
    expect(page).to have_content("Slug has already been taken")
    expect(page).to have_css("#step-7:not([hidden])")
    expect(page).to have_field("mission-name", with: "First Signal", visible: :all)
    find(".step-dot[data-step='4']").click
    fill_in "mission-slug", with: "first-signal-2"
    3.times { click_button "[>] NEXT" }
    click_button "[CREATE MISSION]"

    expect(page).to have_content("Mission 'First Signal' created via wizard.")
    mission = GridMission.find_by!(slug: "first-signal-2")
    expect(mission.grid_mission_objectives.pluck(:label)).to eq(["Find the drop"])
    expect(mission.grid_mission_rewards.pluck(:reward_type, :amount)).to eq([["xp", 30]])

    within("#rewards-rows") { first("[data-row-remove]").click }
    expect(page).to have_css("#rewards-rows .rc-row", count: 1)
    click_button "[SAVE MISSION]"
    expect(page).to have_content("Mission 'First Signal' updated.")
    expect(mission.grid_mission_rewards.reload).to be_empty
    expect(mission.grid_mission_objectives.pluck(:label)).to eq(["Find the drop"])
  end

  # Phase 5: a tester's terminal keeps its own fetch prompt (ids kept,
  # the echo and the end state on classes / `hidden`): a command's reply
  # lands in the pane, and a breach that ends swaps the input for the
  # ended line and hides [ABORT]. The script reads the csrf-token meta,
  # which the layout renders only with forgery protection on.
  it "runs commands in the BREACH sandbox terminal until the breach ends" do
    forgery = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_DEV_TOOLS").and_return("true")
    runner = create(:grid_hackr, hackr_alias: "Runner", current_room: create(:grid_room))
    deck_def = create(:grid_item_definition, :gear, slug: "test-deck", name: "Test Deck",
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "module_slot_count" => 1, "effects" => {}})
    create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: runner).update!(equipped_slot: "deck")
    breach = Grid::BreachService.start_sandbox!(hackr: runner, template: create(:grid_breach_template)).hackr_breach
    log_in!
    visit "/root/grid_breach_sandbox/#{breach.id}"

    expect(page).to have_css("#abort-form")
    expect(page).to have_no_css("#breach-ended")
    find("#command-input").send_keys("status", :enter)
    expect(page).to have_css("#breach-output .rc-term-echo", text: "> status")

    find("#command-input").send_keys("abort", :enter)
    expect(page).to have_css("#breach-ended", text: "SANDBOX BREACH ENDED")
    expect(page).to have_no_css("#command-section")
    expect(page).to have_no_css("#abort-form")
    expect(breach.reload.active?).to be(false)
  ensure
    ActionController::Base.allow_forgery_protection = forgery
  end
end
