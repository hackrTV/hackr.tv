require "rails_helper"

# Phase 2: server-rendered registration end-to-end — email step, mailed
# token, completion form, auto-login into the SPA-served /grid.
RSpec.describe "Hotwire registration", type: :system do
  before do
    # provision_economy! needs base component definitions
    %w[basic-motherboard basic-psu basic-cpu basic-gpu basic-ram].each_with_index do |slug, i|
      slots = %w[motherboard psu cpu gpu ram]
      props = {"slot" => slots[i], "rate_multiplier" => 1.0}
      props.merge!("cpu_slots" => 1, "gpu_slots" => 2, "ram_slots" => 2) if slug == "basic-motherboard"
      create(:grid_item_definition, slug: slug, name: "Basic #{slots[i].capitalize}", item_type: "rig_component", properties: props)
    end
  end

  it "registers from email through completion" do
    visit "/grid/register"
    fill_in "email", with: "operator@example.com"
    click_button "SEND VERIFICATION"

    expect(page).to have_content("CHECK YOUR INBOX")
    expect(page).to have_content("operator@example.com")

    token = GridRegistrationToken.last
    expect(token.email).to eq("operator@example.com")

    visit "/grid/verify/#{token.token}"
    expect(page).to have_content("ALMOST THERE")
    expect(page).to have_content("Email verified: operator@example.com")

    # Server-side validation error re-renders the form
    fill_in "hackr_alias", with: "abc"
    fill_in "password", with: "S3cure-Pass!"
    fill_in "password_confirmation", with: "S3cure-Pass!"
    click_button "JOIN GRID"
    expect(page).to have_content("Registration failed:")

    fill_in "hackr_alias", with: "FreshOperator"
    fill_in "password", with: "S3cure-Pass!"
    fill_in "password_confirmation", with: "S3cure-Pass!"
    click_button "JOIN GRID"

    expect(page).to have_current_path("/grid")
    expect(GridHackr.find_by(hackr_alias: "FreshOperator")).to be_present
  end

  it "shows the failure panel for a dead token" do
    visit "/grid/verify/not-a-real-token"

    expect(page).to have_content("VERIFICATION FAILED")
    expect(page).to have_content("Invalid verification link.")
    expect(page).to have_link("REGISTER AGAIN", href: "/grid/register")
  end
end
