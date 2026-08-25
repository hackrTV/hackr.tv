require "rails_helper"

# Phase 2: server-rendered identity page — bio (with the Stimulus char
# counter), email change end-to-end, reset credentials.
RSpec.describe "Hotwire identity page", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid", email: "old@example.com") }

  def log_in!
    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  it "edits the bio with a live counter and surfaces validation errors" do
    log_in!
    visit "/grid/identity"

    expect(page).to have_content("HACKR SETTINGS")
    expect(page).to have_content("0/512") # Stimulus counter initialized

    fill_in "bio", with: "Signal is everywhere."
    expect(page).to have_content("21/512") # live update

    click_button "SAVE BIO"
    expect(page).to have_content("Bio updated.")
    expect(hackr.reload.bio).to eq("Signal is everywhere.")

    fill_in "bio", with: "reach me at op@example.com"
    click_button "SAVE BIO"
    expect(page).to have_content("can't contain an email address")
    expect(hackr.reload.bio).to eq("Signal is everywhere.")
  end

  it "changes email end-to-end via the confirm page" do
    log_in!
    visit "/grid/identity"

    fill_in "new_email", with: "old@example.com"
    click_button "CHANGE EMAIL"
    expect(page).to have_content("New email must be different from your current email.")

    fill_in "new_email", with: "next@example.com"
    click_button "CHANGE EMAIL"
    expect(page).to have_content("Verification email sent to next@example.com")

    token = GridVerificationToken.where(purpose: "email_change").last
    visit "/grid/confirm_email_change/#{token.token}"
    expect(page).to have_content("CONFIRM EMAIL CHANGE")
    expect(page).to have_content("next@example.com")
    expect(hackr.reload.email).to eq("old@example.com") # GET does not consume

    click_button "CONFIRM EMAIL CHANGE"
    expect(page).to have_content("EMAIL UPDATED")
    expect(hackr.reload.email).to eq("next@example.com")

    click_link "BACK TO IDENTITY"
    expect(page).to have_content("next@example.com")
  end

  it "sends a reset-credentials email" do
    log_in!
    visit "/grid/identity"

    click_button "RESET CREDENTIALS"

    expect(page).to have_content("Password reset email sent. Check your inbox.")
    expect(GridVerificationToken.where(purpose: "password_reset", grid_hackr: hackr)).to exist
  end

  it "redirects anonymous visitors to the Hotwire login page" do
    visit "/grid/identity"

    expect(page).to have_current_path("/grid/login")
    expect(page).to have_content("Access denied. Please log in to THE PULSE GRID.")
  end
end
