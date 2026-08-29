require "rails_helper"

# Phase 2: server-rendered TOTP management — full enable → backup codes →
# regenerate → disable loop, driving real ROTP codes read off the page.
RSpec.describe "Hotwire two-factor management", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  # verify_otp's replay guard (otp_last_used_at) blocks a second use of the
  # same 30s window inside one fast-running spec — clear it between ops.
  def clear_replay_guard!
    hackr.reload.update_column(:otp_last_used_at, nil)
  end

  it "enables, regenerates, and disables 2FA" do
    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")

    visit "/grid/identity"
    expect(page).to have_content("[ INACTIVE ]")
    click_link "MANAGE 2FA"

    expect(page).to have_content("STATUS:")
    expect(page).to have_content("INACTIVE")
    click_link "ENABLE TWO-FACTOR AUTH"

    expect(page).to have_content("STEP 1: SCAN QR CODE")
    secret = find(".tf-secret-box").text.strip
    expect(secret).to match(/\A[A-Z2-7]+\z/)

    # Wrong password error keeps the staged secret
    fill_in "password", with: "wrong"
    fill_in "code", with: ROTP::TOTP.new(secret).now
    click_button "ACTIVATE 2FA"
    expect(page).to have_content("Password incorrect.")
    expect(find(".tf-secret-box").text.strip).to eq(secret)

    fill_in "password", with: "hackthegrid"
    fill_in "code", with: ROTP::TOTP.new(secret).now
    click_button "ACTIVATE 2FA"

    expect(page).to have_content("SAVE THESE BACKUP CODES — SHOWN ONCE ONLY")
    first_codes = all(".backup-codes-grid div").map(&:text)
    expect(first_codes.length).to eq(8)
    expect(hackr.reload.otp_required_for_login).to be(true)

    click_link "I HAVE SAVED THESE CODES"
    expect(page).to have_content("ACTIVE")
    expect(page).to have_content("BACKUP CODES REMAINING: 8")

    # Regenerate
    click_link "REGENERATE BACKUP CODES"
    expect(page).to have_content("This will invalidate all existing backup codes")
    fill_in "password", with: "hackthegrid"
    fill_in "code", with: ROTP::TOTP.new(secret).now
    click_button "REGENERATE CODES"

    expect(page).to have_content("SAVE THESE BACKUP CODES — SHOWN ONCE ONLY")
    second_codes = all(".backup-codes-grid div").map(&:text)
    expect(second_codes.length).to eq(8)
    expect(second_codes).not_to eq(first_codes)
    click_link "I HAVE SAVED THESE CODES"

    # Disable (fresh TOTP window needed after the regenerate verification)
    clear_replay_guard!
    click_link "DISABLE TWO-FACTOR AUTH"
    fill_in "password", with: "hackthegrid"
    fill_in "code", with: ROTP::TOTP.new(secret).now
    click_button "CONFIRM DISABLE"

    expect(page).to have_content("Two-factor authentication disabled.")
    expect(page).to have_content("INACTIVE")
    expect(hackr.reload.otp_required_for_login).to be(false)
    expect(hackr.otp_secret).to be_nil
  end
end
