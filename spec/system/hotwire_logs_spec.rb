require "rails_helper"

# Phase 1: server-rendered Hackr Logs with Turbo Drive navigation.
RSpec.describe "Hotwire logs pages", type: :system do
  let!(:log) do
    create(:hackr_log, :published, title: "Fracture Dispatch One",
      body: "The **resistance** continues.", timeline: "2120s")
  end
  let!(:other_timeline_log) do
    create(:hackr_log, :published, title: "GovCorp Memo Nine", timeline: "govcorp_files")
  end

  it "browses index → detail → back via Turbo, with timeline tabs and sort" do
    visit "/logs"
    page.execute_script("window.__turbo_marker = true")

    expect(page).to have_content("HACKR LOGS")
    expect(page).to have_content("Fracture Dispatch One")
    expect(page).to have_no_content("GovCorp Memo Nine") # other timeline

    # Timeline tab switch (inline or side variant, whichever is visible)
    find(".logs-tabs-side, .logs-tabs-inline", match: :first).click_link(text: /GOVCORP FILES/)
    expect(page).to have_content("GovCorp Memo Nine")

    # Sort toggle link present
    expect(page).to have_link("Newest first ↓")

    # Detail via Turbo (window marker survives)
    find(".logs-tabs-side, .logs-tabs-inline", match: :first).click_link(text: /FRACTURE NETWORK/)
    click_link "Fracture Dispatch One"
    expect(page).to have_css(".log-detail-title", text: "Fracture Dispatch One")
    expect(page).to have_css(".log-detail-prose strong", text: "resistance")
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true)

    click_link "← Back to All Logs"
    expect(page).to have_content("HACKR LOGS")
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true)
  end
end
