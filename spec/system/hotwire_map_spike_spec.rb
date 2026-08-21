require "rails_helper"

# Phase 0 spike B: server-rendered isometric SVG zone map + Stimulus
# pan/zoom/select. Findings feed phase_6_grid.md (6c) and the project-plan
# decision log.
RSpec.describe "Hotwire map spike", type: :system do
  let(:zone) { create(:grid_zone) }
  let!(:hub) { create(:grid_room, grid_zone: zone, name: "Central Hub", room_type: "hub") }
  let!(:east_room) { create(:grid_room, grid_zone: zone, name: "East Wing", room_type: "standard") }
  let!(:north_room) { create(:grid_room, grid_zone: zone, name: "North Vault", room_type: "shop") }
  let(:hackr) { create(:grid_hackr, current_room: hub) }

  before do
    create(:grid_exit, from_room: hub, to_room: east_room, direction: "east", locked: false, requires_item_id: nil)
    create(:grid_exit, from_room: east_room, to_room: hub, direction: "west", locked: false, requires_item_id: nil)
    create(:grid_exit, from_room: hub, to_room: north_room, direction: "north", locked: false, requires_item_id: nil)
    create(:grid_room_visit, grid_hackr: hackr, grid_room: hub)
    create(:grid_room_visit, grid_hackr: hackr, grid_room: east_room)
  end

  def visit_map
    visit "/dev/hotwire/map?hackr_id=#{hackr.id}&zone_id=#{zone.id}"
  end

  it "renders the zone as server-side SVG with fog-of-war styling" do
    visit_map

    expect(page).to have_content("MAP SPIKE — #{zone.name}")
    expect(page).to have_css("svg g[data-room-id='#{hub.id}']")
    expect(page).to have_css("svg g[data-room-id='#{east_room.id}']")
    # Visited rooms show their names; the adjacent-unvisited room shows no label
    expect(page).to have_css("svg text", text: "Central Hub")
    expect(page).to have_css("svg text", text: "East Wing")
    expect(page).to have_no_css("svg text", text: "North Vault")
    # Presence badge: the hackr is in the hub
    expect(page).to have_css("g[data-room-id='#{hub.id}'] circle")
  end

  it "selects a room on click and zooms on wheel" do
    visit_map

    find("g[data-room-id='#{east_room.id}']").click
    expect(page).to have_css("#spike-map-selected", text: "East Wing")

    before_transform = page.evaluate_script("document.querySelector('[data-spike-map-target=world]').getAttribute('transform')")
    page.execute_script(<<~JS)
      const el = document.querySelector('[data-controller="spike-map"]')
      el.dispatchEvent(new WheelEvent('wheel', {deltaY: -120, bubbles: true, cancelable: true}))
    JS
    after_transform = page.evaluate_script("document.querySelector('[data-spike-map-target=world]').getAttribute('transform')")
    expect(after_transform).to include("scale(1.25)")
    expect(after_transform).not_to eq(before_transform)
  end
end
