require "rails_helper"

# Phase 6a: the legacy PULSE GRID terminal on Hotwire. The two-session
# say example is the slice's exit criterion — a room event lands live in
# another browser via the per-room grid_room_html stream while the JSON
# GridChannel keeps serving the React tactical page.
RSpec.describe "Hotwire grid game", type: :system do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone, name: "Neon Atrium") }

  def make_hackr(alias_name)
    hackr = create(:grid_hackr, hackr_alias: alias_name, password: "hackthegrid",
      current_room: room, stats: {"tutorial_completed" => true})
    create(:feature_grant, grid_hackr: hackr, feature: FeatureGrant::PULSE_GRID)
    hackr
  end

  let!(:hackr) { make_hackr("NeonRunner") }
  let!(:other) { make_hackr("WireGhost") }

  def log_in!(as)
    visit "/grid/login"
    fill_in "hackr_alias", with: as.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  def await_grid!
    expect(page).to have_content("WELCOME TO THE PULSE GRID")
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
  end

  def run_command(text)
    fill_in "input", with: text
    find(".grid-command-input").send_keys(:enter)
  end

  it "renders the welcome + initial look and executes commands without reload" do
    log_in!(hackr)
    await_grid!

    expect(page).to have_content("NEON ATRIUM")
    page.execute_script("window.__turbo_marker = true")

    run_command("say testing the wire")

    # Echo is instant client-side; the say line arrives via broadcast.
    expect(page).to have_content("> say testing the wire", wait: 10)
    expect(page).to have_content("[NeonRunner]: testing the wire", wait: 10)
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # no reload
    expect(page).to have_field("input", with: "")
  end

  it "delivers room events to other hackrs live (exit criterion)" do
    using_session(:watcher) do
      log_in!(other)
      await_grid!
      page.execute_script("window.__turbo_marker = true")
    end

    using_session(:actor) do
      log_in!(hackr)
      await_grid!
      run_command("say cross-session grid test")
      expect(page).to have_content("[NeonRunner]: cross-session grid test", wait: 10)
    end

    using_session(:watcher) do
      expect(page).to have_content("[NeonRunner]: cross-session grid test", wait: 10)
      expect(page.evaluate_script("window.__turbo_marker")).to eq(true)
    end
  end

  it "moves between rooms, swaps the stream, and broadcasts the departure" do
    target = create(:grid_room, grid_zone: zone, name: "Fiber Alley")
    create(:grid_exit, from_room: room, to_room: target, direction: "north", requires_item_id: nil)
    create(:grid_exit, from_room: target, to_room: room, direction: "south", requires_item_id: nil)

    using_session(:watcher) do
      log_in!(other)
      await_grid!
    end

    using_session(:mover) do
      log_in!(hackr)
      await_grid!
      run_command("go north")
      expect(page).to have_content("FIBER ALLEY", wait: 10)
      expect(page).to have_css(%([data-grid-room-id="#{target.id}"]), visible: :all, wait: 10)
    end

    using_session(:watcher) do
      expect(page).to have_content("NeonRunner leaves to the north.", wait: 10)
    end

    # The mover's swapped subscription receives the NEW room's events.
    using_session(:mover) do
      run_command("say made it to the alley")
      expect(page).to have_content("[NeonRunner]: made it to the alley", wait: 10)
    end
  end

  it "recalls command history with the arrow keys" do
    log_in!(hackr)
    await_grid!

    run_command("look")
    expect(page).to have_content("> look")
    run_command("who")
    expect(page).to have_content("> who")

    find(".grid-command-input").send_keys(:up)
    expect(page).to have_field("input", with: "who")
    find(".grid-command-input").send_keys(:up)
    expect(page).to have_field("input", with: "look")
    find(".grid-command-input").send_keys(:down)
    expect(page).to have_field("input", with: "who")
  end

  it "clears the log client-side without a round-trip" do
    log_in!(hackr)
    await_grid!
    expect(page).to have_content("NEON ATRIUM")

    command_count = GridMessage.count
    run_command("clear")

    expect(page).not_to have_content("WELCOME TO THE PULSE GRID")
    expect(page).not_to have_content("NEON ATRIUM")
    expect(page).to have_field("input", with: "")
    expect(GridMessage.count).to eq(command_count) # nothing hit the server
  end

  it "keeps the permanent player alive navigating vault → /grid (Turbo nav)" do
    artist = create(:artist, name: "Wave Artist")
    release = create(:release, artist: artist)
    create(:track, :with_audio, artist: artist, release: release, title: "Grid Tone")

    log_in!(hackr)
    visit "/vault"
    find(".track-row", text: "Grid Tone").click
    expect(page).to have_button("❚❚ PAUSE", id: "play-pause-btn", wait: 10)
    page.execute_script("window.__player_marker = true")

    page.execute_script("window.Turbo.visit('/grid')")

    expect(page).to have_current_path("/grid")
    expect(page).to have_content("WELCOME TO THE PULSE GRID")
    expect(page).to have_css(".player-bar", visible: :visible)
    expect(page.evaluate_script("document.querySelector('#player-bar audio').paused")).to eq(false)
    expect(page.evaluate_script("window.__player_marker")).to eq(true) # Turbo visit, not full load
  end
end
