require "rails_helper"

# Phase 2: server-rendered login incl. the 2FA interstitial. Success lands
# on the SPA-served /grid (cross-stack full-load proof in the Hotwire→SPA
# direction).
RSpec.describe "Hotwire login", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  it "rejects bad credentials with the API's error copy, then logs in" do
    visit "/grid/login"
    expect(page).to have_content("FRACTURE NETWORK LOGIN")

    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "wrong"
    click_button "CONNECT"

    expect(page).to have_content("⚠ ERROR")
    expect(page).to have_content("Invalid hackr alias or password. Access denied.")
    expect(page).to have_field("hackr_alias", with: hackr.hackr_alias) # preserved

    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"

    expect(page).to have_current_path("/grid")
  end

  it "blocks disabled accounts" do
    hackr.update!(login_disabled: true)

    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"

    expect(page).to have_content("This account has been disabled.")
  end

  context "with 2FA enabled" do
    let(:secret) { ROTP::Base32.random }

    before { hackr.update!(otp_secret: secret, otp_required_for_login: true) }

    it "walks the interstitial: wrong code errors, valid code completes login" do
      visit "/grid/login"
      fill_in "hackr_alias", with: hackr.hackr_alias
      fill_in "password", with: "hackthegrid"
      click_button "CONNECT"

      expect(page).to have_content("TWO-FACTOR VERIFICATION")

      fill_in "totp_code", with: "000000"
      click_button "VERIFY"
      expect(page).to have_content("Invalid code. Access denied.")

      fill_in "totp_code", with: ROTP::TOTP.new(secret).now
      click_button "VERIFY"

      expect(page).to have_current_path("/grid")
    end

    it "bounces the verify page without a pending session" do
      visit "/grid/login/verify"

      expect(page).to have_current_path("/grid/login")
      expect(page).to have_content("No pending authentication session")
    end
  end
end
