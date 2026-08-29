require "rails_helper"

# Phase 1: server-rendered timeline with Stimulus nav (scroll + active
# tracking) and fade-cycling atmosphere fragments.
RSpec.describe "Hotwire timeline page", type: :system do
  it "renders eras, scrolls via nav, and cycles gap fragments" do
    visit "/timeline"

    expect(page).to have_content("THE TIMELINE")
    expect(page).to have_css("#listeners")
    expect(page).to have_css("#fracture_network")

    # Fade-cycle controller populated the gap fragment text
    expect(page).to have_css(".tl-gap-text p", text: /The Trade|The Efficiency|The Forgetting|managed silence|No one was listening/, wait: 5)

    # Nav click scrolls to the era section
    find(".tl-nav-btn[data-era='fracture_network']").click
    expect(page).to have_css(".tl-nav-btn.active[data-era='fracture_network']", wait: 5)

    scroll_y = page.evaluate_script("window.scrollY")
    expect(scroll_y).to be > 500
  end
end
