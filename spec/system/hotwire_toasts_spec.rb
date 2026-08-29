require "rails_helper"

# Phase 3: achievement toasts on Hotwire pages via the user-scoped
# [hackr, :toasts] stream (dual-published next to the SPA's JSON).
RSpec.describe "Hotwire toasts", type: :system do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }
  let!(:achievement) do
    create(:grid_achievement, name: "Signal Tapper", category: "social",
      badge_icon: "📡", xp_reward: 50, cred_reward: 10, description: "Tapped the signal.")
  end

  it "pops an achievement toast on a Hotwire page and dismisses on click" do
    visit "/grid/login"
    fill_in "hackr_alias", with: hackr.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")

    visit "/wire"
    expect(page).to have_content("The WIRE")
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, count: 2, wait: 10)

    Grid::AchievementAwarder.new(hackr, achievement).award!

    expect(page).to have_content("ACHIEVEMENT UNLOCKED", wait: 10)
    expect(page).to have_content("[SOCIAL]")
    expect(page).to have_content("Signal Tapper")
    expect(page).to have_content("+50 XP")

    find(".toast").click
    expect(page).to have_no_content("ACHIEVEMENT UNLOCKED")
  end
end
