require "rails_helper"

# Phase 2: server-rendered forgot/reset password flows.
RSpec.describe "Hotwire password reset", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid", email: "op@example.com") }

  it "requests a reset and sets a new password" do
    visit "/grid/forgot_password"
    fill_in "email", with: "op@example.com"
    click_button "SEND RESET LINK"

    expect(page).to have_content("CHECK YOUR INBOX")
    expect(page).to have_content("If an account exists for")

    token = GridVerificationToken.last
    expect(token.purpose).to eq("password_reset")

    visit "/grid/reset_password/#{token.token}"
    expect(page).to have_content("ENTER NEW CREDENTIALS")

    # Mismatch surfaces the model error
    fill_in "password", with: "new-passphrase-9"
    fill_in "password_confirmation", with: "different-pass"
    click_button "RESET PASSWORD"
    expect(page).to have_content("Password update failed:")

    fill_in "password", with: "new-passphrase-9"
    fill_in "password_confirmation", with: "new-passphrase-9"
    click_button "RESET PASSWORD"

    expect(page).to have_current_path("/grid/login")
    expect(page).to have_content("Password updated successfully. Log in with your new credentials.")

    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "new-passphrase-9"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  it "shows the failure panel for an expired token" do
    token = GridVerificationToken.create!(grid_hackr: hackr, purpose: "password_reset")
    token.update!(expires_at: 1.hour.ago)

    visit "/grid/reset_password/#{token.token}"

    expect(page).to have_content("VERIFICATION FAILED")
    expect(page).to have_content("This reset link has expired.")
    expect(page).to have_link("REQUEST A NEW LINK", href: "/grid/forgot_password")
  end
end
