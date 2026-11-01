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
end
