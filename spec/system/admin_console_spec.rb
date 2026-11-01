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
end
