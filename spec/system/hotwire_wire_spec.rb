require "rails_helper"

# Phase 3: the WIRE on Turbo Streams. The two-session example is the
# phase's exit criterion — a pulse posted in one browser session appears
# live in another via the wire_html stream (dual-publish keeps the JSON
# channel for overlays).
RSpec.describe "Hotwire wire feed", type: :system do
  # Admin roles: the WIRE is admin-only while in admin preview
  # (admin_preview_spec pins the gate); viewer sessions log in too since
  # anonymous visitors now get the coming-soon page.
  let!(:hackr) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:other) { create(:grid_hackr, :admin, password: "hackthegrid") }

  def log_in!(as)
    visit "/grid/login"
    fill_in "hackr_alias", with: as.hackr_alias
    fill_in "password", with: "hackthegrid"
    click_button "CONNECT"
    expect(page).to have_current_path("/grid")
  end

  # The context pane opens by default at the suite's 1400px and claims
  # thread opens; the inline examples close it first (the c key).
  def close_pane!
    expect(page).to have_css(".wire-page[data-pane='open']")
    find("body").send_keys("c")
    expect(page).to have_no_css(".wire-page[data-pane='open']")
  end

  it "composes with a live counter and prepends the pulse without reload" do
    log_in!(hackr)
    visit "/wire"

    expect(page).to have_content("The WIRE")
    expect(page).to have_content("256 / 256")
    expect(page).to have_button("Broadcast", disabled: true)

    fill_in "content", with: "First transmission from the Hotwire."
    expect(page).to have_content("#{256 - 36} / 256")
    expect(page).to have_button("Broadcast", disabled: false)

    page.execute_script("window.__turbo_marker = true")
    click_button "Broadcast"

    expect(page).to have_content("First transmission from the Hotwire.")
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # no reload
    expect(page).to have_field("content", with: "") # composer reset
    expect(Pulse.last.content).to eq("First transmission from the Hotwire.")
  end

  it "delivers a pulse posted in one session to another live (exit criterion)" do
    using_session(:viewer) do
      log_in!(hackr)
      visit "/wire"
      expect(page).to have_content("The WIRE")
      expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
      page.execute_script("window.__turbo_marker = true")
    end

    using_session(:poster) do
      log_in!(other)
      visit "/wire"
      fill_in "content", with: "Cross-session signal test."
      click_button "Broadcast"
      expect(page).to have_content("Cross-session signal test.")
    end

    using_session(:viewer) do
      expect(page).to have_content("Cross-session signal test.", wait: 10)
      expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # arrived via stream
    end
  end

  it "toggles echoes and pushes count updates to other sessions" do
    pulse = create(:pulse, grid_hackr: other, content: "Echo relay target")

    using_session(:viewer) do
      log_in!(other)
      visit "/wire"
      expect(page).to have_content("Echo relay target")
      expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
    end

    using_session(:echoer) do
      log_in!(hackr)
      visit "/wire"
      within("#pulse_#{pulse.id}") { find(".echo-button").click }
      expect(page).to have_css("#pulse_#{pulse.id} .echo-button.echoed", wait: 10)
      expect(page).to have_css("#pulse_#{pulse.id} .echo-count", text: "1")
    end

    using_session(:viewer) do
      expect(page).to have_css("#pulse_#{pulse.id} .echo-count", text: "1", wait: 10)
      expect(page).to have_no_css("#pulse_#{pulse.id} .echo-button.echoed") # per-viewer state untouched
    end
  end

  it "reveals owner controls and deletes everywhere" do
    pulse = create(:pulse, grid_hackr: hackr, content: "Doomed broadcast")

    using_session(:viewer) do
      log_in!(other)
      visit "/wire"
      expect(page).to have_content("Doomed broadcast")
      expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
    end

    using_session(:owner) do
      log_in!(hackr)
      visit "/wire"
      within("#pulse_#{pulse.id}") { find(".delete-button").click }
      expect(page).to have_no_content("Doomed broadcast", wait: 10)
    end

    using_session(:viewer) do
      expect(page).to have_no_content("Doomed broadcast", wait: 10)
    end
  end

  it "expands a thread inline, splices into it, and folds it again without leaving the feed" do
    root = create(:pulse, grid_hackr: other, content: "Root of the thread")
    create(:pulse, grid_hackr: other, content: "Earlier splice", parent_pulse_id: root.id)
    log_in!(hackr)
    visit "/wire"
    close_pane!
    page.execute_script("window.__turbo_marker = true")

    within("#pulse_#{root.id}") { find(".splice-button").click }
    within("#pulse_#{root.id}_thread") do
      expect(page).to have_content("Earlier splice")
      fill_in "content", with: "Spliced response."
      click_button "Splice"
      expect(page).to have_content("Spliced response.")
    end
    expect(page).to have_css("#pulse_#{root.id} .splice-count", text: "2")
    expect(page).to have_current_path("/wire")
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # frames + streams, no navigation

    within("#pulse_#{root.id}") { find(".splice-button").click } # fold
    expect(page).to have_no_content("Earlier splice")
    within("#pulse_#{root.id}") { find(".splice-button").click } # unfold: still there, no refetch needed
    expect(page).to have_content("Earlier splice")
  end

  it "walks the ledger with the keyboard: j/k cursor, e echoes, o opens the thread, x x deletes own" do
    create(:pulse, grid_hackr: other, content: "Newest pulse")
    target = create(:pulse, grid_hackr: other, content: "Key target", pulsed_at: 1.minute.ago)
    mine = create(:pulse, grid_hackr: hackr, content: "My own pulse", pulsed_at: 2.minutes.ago)
    log_in!(hackr)
    visit "/wire"
    expect(page).to have_content("Key target")
    close_pane!

    find("body").send_keys("j", "j")
    expect(page).to have_css("#pulse_#{target.id}.wire-row--cursor")
    find("body").send_keys("e")
    expect(page).to have_css("#pulse_#{target.id} .echo-button.echoed")
    find("body").send_keys("o")
    expect(page).to have_css("#pulse_#{target.id} .splice-button[aria-expanded='true']", wait: 5)
    expect(page).to have_field("content", count: 2) # the thread's reply prompt opened

    find("body").send_keys("k", "j", "j") # down past the opened thread's (empty) list onto my own pulse
    expect(page).to have_css("#pulse_#{mine.id}.wire-row--cursor")
    find("body").send_keys("x")
    expect(page).to have_css("#pulse_#{mine.id}.wire-row--armed")
    find("body").send_keys("x")
    expect(page).to have_no_content("My own pulse", wait: 5)

    find("body").send_keys("?")
    expect(page).to have_css(".wire-legend", visible: true)
    find("body").send_keys(:escape)
    expect(page).to have_css(".wire-legend", visible: :hidden)
  end

  it "keeps an open thread when its root is dropped elsewhere, emptying the reply prompt" do
    root = create(:pulse, grid_hackr: other, content: "Doomed root")
    create(:pulse, grid_hackr: other, content: "Its splice", parent_pulse_id: root.id)
    log_in!(hackr)
    visit "/wire"
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
    close_pane!
    within("#pulse_#{root.id}") { find(".splice-button").click }
    expect(page).to have_content("Its splice")

    root.pulse_drop!

    expect(page).to have_content("[ PULSE DROPPED BY GOVCORP ]", wait: 10)
    expect(page).to have_css("#pulse_#{root.id}_entry") # the entry survives the row replace
    expect(page).to have_no_content("Its splice") # a dropped root's thread is emptied
  end

  it "reads threads in the context pane: the cursor is followed, splices land there, r aims its prompt, an alias shows the record, c closes it and ↩ falls back inline" do
    root = create(:pulse, grid_hackr: other, content: "Root of the pane thread")
    create(:pulse, grid_hackr: other, content: "Earlier splice", parent_pulse_id: root.id)
    create(:pulse, grid_hackr: other, content: "Newest pulse")
    log_in!(hackr)
    visit "/wire"
    expect(page).to have_css(".wire-page[data-pane='open']") # open by default at 1400px
    expect(page).to have_css(".wire-bar-pane[aria-pressed='true']")
    expect(page).to have_content("// SELECT A PULSE //")
    page.execute_script("window.__turbo_marker = true")

    find("body").send_keys("j", "j") # the cursor is followed into the pane
    expect(page).to have_css("#pulse_#{root.id}.wire-row--sel")
    within("#wire-pane") do
      expect(page).to have_content("THREAD")
      expect(page).to have_content("Root of the pane thread")
      expect(page).to have_content("Earlier splice")
      fill_in "content", with: "Spliced from the pane."
      click_button "Splice"
      expect(page).to have_content("Spliced from the pane.")
    end
    expect(page).to have_css("#pulse_#{root.id} .splice-count", text: "2")
    expect(page).to have_no_css("#pulse_#{root.id}_thread .wire-row") # the inline frame stayed empty

    find("body").send_keys("r")
    expect(page.evaluate_script("document.activeElement.closest('#wire-pane') !== null")).to eq(true)
    expect(find("#wire-pane .wire-prompt-input").value).to eq("") # no stray "r"
    find("#wire-pane .wire-prompt-input").send_keys(:escape)

    within("#pulse_#{root.id}") { click_link "@#{other.hackr_alias}" }
    within("#wire-pane") do
      expect(page).to have_content("OPERATIVE")
      expect(page).to have_link("[>] PROFILE")
    end
    expect(page).to have_current_path("/wire")
    expect(page).to have_no_css(".wire-row--sel")

    find("#pulse_#{root.id} .wire-text").click # a click on the row is a cursor move: the thread is back
    expect(page).to have_css("#pulse_#{root.id}.wire-row--cursor")
    expect(page).to have_css("#pulse_#{root.id}.wire-row--sel")
    within("#wire-pane") { expect(page).to have_content("Spliced from the pane.") }

    find("body").send_keys("c")
    expect(page).to have_no_css(".wire-page[data-pane='open']")
    within("#pulse_#{root.id}") { find(".splice-button").click }
    within("#pulse_#{root.id}_thread") { expect(page).to have_content("Earlier splice") }
    expect(page.evaluate_script("window.__turbo_marker")).to eq(true) # frames + streams, no navigation

    find("body").send_keys("c") # reopening onto the cursor row moves that thread into the pane: one list on the page
    expect(page).to have_css(".wire-page[data-pane='open']")
    within("#wire-pane") { expect(page).to have_content("Earlier splice") }
    expect(page).to have_no_css("#pulse_#{root.id}_thread .wire-row")
    expect(page).to have_css("#pulse_#{root.id}_thread_list", count: 1, visible: :all)
    find("body").send_keys("c")

    visit "/wire" # the choice is remembered
    expect(page).to have_content("Root of the pane thread")
    expect(page).to have_no_css(".wire-page[data-pane='open']")
    expect(page).to have_css(".wire-bar-pane[aria-pressed='false']")
  end

  it "keeps threads inline under the pane's minimum width" do
    root = create(:pulse, grid_hackr: other, content: "Narrow root")
    create(:pulse, grid_hackr: other, content: "Narrow splice", parent_pulse_id: root.id)
    log_in!(hackr)
    page.driver.resize(1024, 800)
    visit "/wire"

    expect(page).to have_content("Narrow root")
    expect(page).to have_no_css(".wire-page[data-pane='open']")
    expect(page).to have_no_css(".wire-bar-pane", visible: true)
    expect(page).to have_no_css(".wire-bar-view", visible: true)
    within("#pulse_#{root.id}") { find(".splice-button").click }
    within("#pulse_#{root.id}_thread") { expect(page).to have_content("Narrow splice") }
    find("body").send_keys("v") # MUTT needs the width too
    expect(page).to have_no_css(".wire-page.wire-mutt")
    expect(page).to have_content("Narrow splice")
  ensure
    page.driver.resize(1400, 900)
  end

  it "reads the WIRE as mutt: v flips to the index/pager shell, the cursor opens on the first line, flags mark own/echoed/new, v returns" do
    mine = create(:pulse, grid_hackr: hackr, content: "My index line", pulsed_at: 2.minutes.ago)
    target = create(:pulse, grid_hackr: other, content: "Index target", pulsed_at: 1.minute.ago)
    create(:pulse, grid_hackr: other, content: "Target splice", parent_pulse_id: target.id)

    using_session(:poster) do
      log_in!(other)
      visit "/wire"
      expect(page).to have_content("Index target")
    end

    log_in!(hackr)
    visit "/wire"
    expect(page).to have_css(".wire-bar-view", text: "[≡] MUTT")
    find("body").send_keys("v")
    expect(page).to have_css(".wire-page.wire-mutt") # the cookie + an in-place visit
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all, wait: 10)
    expect(page).to have_css("#pulse_#{target.id}.wire-row--cursor") # the newest line
    within("#wire-pane") { expect(page).to have_content("Target splice") } # the pager followed
    expect(page).to have_css(".wire-mutt-status", text: "[Pulses:2 New:0]")
    expect(page).to have_css(".wire-mutt-status", text: "(1/2)")
    expect(page).to have_css("#pulse_#{mine.id} .wire-fl--f", visible: true)
    expect(page).to have_css("#pulse_#{target.id} .wire-fl--f", visible: :hidden)
    expect(page).to have_css("#pulse_#{target.id} .wire-fl--e", visible: :hidden)
    find("body").send_keys("e")
    expect(page).to have_css("#pulse_#{target.id} .wire-fl--e", visible: true)

    using_session(:poster) do
      fill_in "content", with: "Fresh arrival."
      click_button "Broadcast"
      expect(page).to have_content("Fresh arrival.")
    end

    expect(page).to have_content("Fresh arrival.", wait: 10)
    fresh = Pulse.find_by!(content: "Fresh arrival.")
    expect(page).to have_css("#pulse_#{fresh.id} .wire-fl--n", visible: true)
    expect(page).to have_css(".wire-mutt-status", text: "[Pulses:3 New:1]")
    find("body").send_keys("k") # reading it clears N
    expect(page).to have_css("#pulse_#{fresh.id}.wire-row--cursor")
    expect(page).to have_css("#pulse_#{fresh.id} .wire-fl--n", visible: :hidden)
    expect(page).to have_css(".wire-mutt-status", text: "New:0]")
    expect(page).to have_css(".wire-mutt-status", text: "(1/3)")

    find("#pulse_#{mine.id} .wire-text").click # a click on a line moves the cursor, the pager follows
    expect(page).to have_css("#pulse_#{mine.id}.wire-row--cursor")
    expect(page).to have_css(".wire-mutt-status", text: "(3/3)")
    within("#wire-pane") { expect(page).to have_content("My index line") }

    find("body").send_keys("v")
    expect(page).to have_no_css(".wire-page.wire-mutt")
    expect(page).to have_css(".wire-bar-view", text: "[≡] MUTT")
    visit "/wire"
    expect(page).to have_content("Index target")
    expect(page).to have_no_css(".wire-page.wire-mutt") # remembered
  end

  it "shows the owner's delete control without hover on a phone-width viewport" do
    mine = create(:pulse, grid_hackr: hackr, content: "Pocket pulse")
    log_in!(hackr)
    page.driver.resize(390, 800)
    visit "/wire"

    within("#pulse_#{mine.id}") { expect(page).to have_css(".delete-button", visible: true) }
    expect(page).to have_no_css(".wire-bar-keys", visible: true)
  ensure
    page.driver.resize(1400, 900)
  end
end
