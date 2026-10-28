require "rails_helper"

# Server-rendered PulseWire pages + form endpoints (Hotwire migration
# Phase 3). The JSON API keeps its own specs.
RSpec.describe "Wire pages", type: :request do
  # Admin role for the viewer/actor: the WIRE is admin-only while in
  # admin preview (admin_preview_spec pins the gate itself). `other`
  # stays a plain operative — poster-role behavior (link censorship)
  # depends on it.
  let!(:hackr) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:other) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(as = hackr)
    post "/grid/login", params: {hackr_alias: as.hackr_alias, password: "hackthegrid"}
  end

  def make_pulse(author = other, content: "Signal check", **attrs)
    create(:pulse, grid_hackr: author, content: content, **attrs)
  end

  describe "GET /wire" do
    it "renders the feed with composer for logged-in hackrs" do
      make_pulse(other, content: "First broadcast")
      log_in!

      get "/wire"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The WIRE")
      expect(response.body).to include("First broadcast")
      expect(response.body).to include("Broadcast on the WIRE...")
      expect(response.body).to include("turbo-cable-stream-source") # live stream subscription
    end

    it "shows the coming-soon gate when anonymous (admin preview)" do
      get "/wire"

      expect(response.body).to include("will open soon")
      expect(response.body).not_to include("Broadcast on the WIRE...")
    end

    it "renders the empty state" do
      log_in!
      get "/wire"

      expect(response.body).to include("The WIRE is silent. Broadcast the first pulse.")
    end

    it "excludes pulse-dropped and splice pulses from the feed" do
      log_in!
      make_pulse(other, content: "Visible pulse")
      dropped = make_pulse(other, content: "Dropped pulse")
      dropped.pulse_drop!
      root = make_pulse(other, content: "Thread root")
      create(:pulse, grid_hackr: hackr, content: "A reply", parent_pulse_id: root.id)

      get "/wire"

      expect(response.body).to include("Visible pulse")
      expect(response.body).not_to include("Dropped pulse")
      expect(response.body).not_to include("A reply")
    end

    it "paginates via a lazy frame" do
      55.times { |i| make_pulse(other, content: "Pulse number #{i}") }
      log_in!

      get "/wire"
      expect(response.body).to include("wire-page-2")

      get "/wire", params: {page: 2}
      expect(response.body).to include("End of the WIRE")
    end

    it "renders censored links for non-admin posters and live links for admins" do
      make_pulse(other, content: "see https://example.com now")
      admin = create(:grid_hackr, :admin, password: "hackthegrid")
      make_pulse(admin, content: "read https://example.com today")
      log_in!

      get "/wire"

      expect(response.body).to include("[LINK CENSORED BY GOVCORP]")
      expect(response.body).to include('<a href="https://example.com"')
    end

    it "renders :slug: emotes in pulses and ships the picker payload on the composer" do
      create(:emote, :gif, slug: "party")
      make_pulse(other, content: "tonight :party: :nope:")
      log_in!

      get "/wire"

      expect(response.body).to include('alt=":party:"')
      expect(response.body).to include('src="/rails/active_storage/blobs/redirect/') # gif: original blob
      expect(response.body).to include(":nope:")
      expect(response.body).to include('data-controller="composer emote-picker"')
      expect(response.body).to include("&quot;slug&quot;:&quot;party&quot;")
      expect(response.body).to include('class="emote-menu emote-menu--down"')
    end

    it "renders ledger rows: entry + row + thread frame per root, role-colored authors, no absent glyphs" do
      pulse = make_pulse(hackr, content: "Ledger row")
      log_in!

      get "/wire"

      expect(response.body).to include(%(id="pulse_#{pulse.id}_entry"))
      expect(response.body).to include(%(id="pulse_#{pulse.id}"))
      expect(response.body).to match(/<turbo-frame[^>]*id="pulse_#{pulse.id}_thread"/)
      expect(response.body).to include("wire-author--admin")
      expect(response.body).to include("wire-badge--admin")
      expect(response.body).to include('data-controller="wire-keys wire-feed wire-pane wire-view"')
      expect(response.body).to include("click->wire-keys#click") # a row click is a cursor move
      expect(response.body).to include("[&gt;] CONTEXT")
      expect(response.body).to match(/<turbo-frame[^>]*id="wire-pane"/)
      expect(response.body).to include("// SELECT A PULSE //")
      expect(response.body).to include("[≡] MUTT")
      expect(response.body).to include(%(<span class="wire-ix-id" aria-hidden="true">#{pulse.id}</span>)) # MUTT's index cells ride every row
      expect(response.body).to include("wire-fl--d")
      expect(response.body).not_to include("⟳")
      expect(response.body).not_to include("📌")
    end

    it "renders the ledger with the pane open from the wire_pane cookie" do
      log_in!
      cookies[:wire_pane] = "open"

      get "/wire"

      expect(response.body).to match(/<div class="wire-page" data-view="ledger"[^>]* data-pane="open"/)
      expect(response.body).to include("chrome-content")
    end

    it "renders MUTT mode from the wire_view cookie: the index/pager shell without the page chrome" do
      pulse = make_pulse(hackr, content: "Index line")
      log_in!
      cookies[:wire_view] = "mutt"

      get "/wire"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="wire-page wire-mutt" data-view="mutt"')
      expect(response.body).to include('data-wire-view-total-value="1"')
      expect(response.body).to include("click->wire-keys#click")
      expect(response.body).to include("wire-ix-head")
      expect(response.body).to include("wire-mutt-status")
      expect(response.body).to include("wire-mutt-keys")
      expect(response.body).to include("[≡] LEDGER")
      expect(response.body).to include("// NO PULSE SELECTED //")
      expect(response.body).to include(%(id="pulse_#{pulse.id}_entry"))
      expect(response.body).to include("Broadcast on the WIRE...")
      expect(response.body).to include("turbo-cable-stream-source")
      expect(response.body).not_to include("chrome-content")
      expect(response.body).not_to include("[&gt;] CONTEXT")

      get "/wire", params: {page: 2} # lazy pages are frames whatever the view
      expect(response.body).to include(%(id="wire-page-2"))
      expect(response.body).not_to include("wire-mutt")
    end
  end

  describe "POST /wire/pulses" do
    it "is gated for anonymous posters (admin preview)" do
      post "/wire/pulses", params: {content: "nope"},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:forbidden)
    end

    it "creates a root pulse and responds with turbo streams" do
      log_in!

      expect {
        post "/wire/pulses", params: {content: "Fresh broadcast"},
          headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change(Pulse, :count).by(1)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('action="prepend"')
      expect(response.body).to include("Fresh broadcast")
      expect(Pulse.last.grid_hackr).to eq(hackr)
    end

    it "redirects a splice to its thread page" do
      root = make_pulse(other, content: "Root")
      log_in!

      post "/wire/pulses", params: {content: "A splice", parent_pulse_id: root.id}

      expect(response).to redirect_to("/wire/pulse/#{root.id}")
      expect(Pulse.last.parent_pulse_id).to eq(root.id)
    end

    it "appends a splice into the open thread and refreshes the root's reply count" do
      root = make_pulse(other, content: "Root")
      log_in!

      post "/wire/pulses", params: {content: "A splice", parent_pulse_id: root.id},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to match(/action="append"[^>]*target="pulse_#{root.id}_thread_list"/)
      expect(response.body).to match(/action="replace"[^>]*target="pulse_#{root.id}_splice_count"/)
      expect(response.body).to include("A splice")
      expect(root.reload.splice_count).to eq(1)
    end

    it "renders the composer error for invalid content" do
      log_in!

      post "/wire/pulses", params: {content: "x" * 300},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("composer-error")
    end

    it "reports a failed splice under its thread's prompt" do
      root = make_pulse(other, content: "Root")
      log_in!

      post "/wire/pulses", params: {content: "x" * 300, parent_pulse_id: root.id},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("pulse_#{root.id}_reply_error")
      expect(response.body).not_to include(%(target="composer-error"))
    end
  end

  describe "DELETE /wire/pulses/:id" do
    it "deletes own pulses only" do
      mine = make_pulse(hackr, content: "Mine")
      theirs = make_pulse(other, content: "Theirs")
      log_in!

      delete "/wire/pulses/#{theirs.id}"
      expect(response).to have_http_status(:not_found)

      expect {
        delete "/wire/pulses/#{mine.id}", headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change(Pulse, :count).by(-1)
    end
  end

  describe "POST /wire/pulses/:id/echo" do
    it "toggles the echo and replaces the button" do
      pulse = make_pulse(other, content: "Echo me")
      log_in!

      expect {
        post "/wire/pulses/#{pulse.id}/echo", headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change(Echo, :count).by(1)
      expect(response.body).to include("echo-button echoed")

      expect {
        post "/wire/pulses/#{pulse.id}/echo", headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change(Echo, :count).by(-1)
      expect(response.body).not_to include("echo-button echoed")
    end
  end

  describe "pins" do
    it "pins up to the cap, moves, and unpins" do
      pulses = 4.times.map { |i| make_pulse(hackr, content: "Pin target #{i}") }
      log_in!

      3.times { |i| post "/wire/pulses/#{pulses[i].id}/pin" }
      expect(hackr.pulse_pins.count).to eq(3)

      post "/wire/pulses/#{pulses[3].id}/pin"
      follow_redirect!
      expect(response.body).to include("You can pin at most 3 pulses")

      patch "/wire/pulses/#{pulses[2].id}/pin/move", params: {direction: "up"}
      expect(hackr.pulse_pins.order(:position).map(&:pulse_id))
        .to eq([pulses[0].id, pulses[2].id, pulses[1].id])

      delete "/wire/pulses/#{pulses[0].id}/pin"
      expect(hackr.pulse_pins.count).to eq(2)
      expect(hackr.pulse_pins.order(:position).map(&:position)).to eq([0, 1])
    end
  end

  describe "GET /wire/:username" do
    it "renders the profile with stats, pinned box, and timeline" do
      pulse = make_pulse(hackr, content: "Profile broadcast")
      pinned = make_pulse(hackr, content: "Pinned broadcast")
      hackr.pulse_pins.create!(pulse: pinned, position: 0)
      echoed = make_pulse(other, content: "Echoed by profile owner")
      Echo.create!(pulse: echoed, grid_hackr: hackr)
      log_in!

      get "/wire/#{hackr.hackr_alias.downcase}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@#{hackr.hackr_alias}")
      expect(response.body).to include("MEMBER SINCE")
      expect(response.body).to include("WIRE PULSES")
      expect(response.body).to include("// PINNED 1/3 //")
      expect(response.body).to include("Pinned broadcast")
      expect(response.body).to include("Profile broadcast")
      expect(response.body).to include("wire-badge--echo") # echo indicator
      expect(response.body).to include("Echoed by profile owner")
      expect(response.body.scan("Pinned broadcast").length).to eq(1) # dedup vs timeline
      expect(pulse).to be_present
    end

    it "canonicalizes case via the LowercaseRedirect middleware" do
      log_in!
      get "/wire/#{hackr.hackr_alias.upcase}"

      expect(response).to have_http_status(:moved_permanently)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@#{hackr.hackr_alias}")
    end

    it "renders NO SIGNAL for unknown hackrs" do
      log_in!
      get "/wire/ghost_alias"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("NO SIGNAL")
      expect(response.body).to include("@ghost_alias")
    end

    it "answers the context pane (frame wire-pane) with the operative record alone" do
      hackr.update!(bio: "Ghost in the wire")
      make_pulse(hackr, content: "Timeline broadcast")
      log_in!

      get "/wire/#{hackr.hackr_alias.downcase}", headers: {"Turbo-Frame" => "wire-pane"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<turbo-frame[^>]*id="wire-pane"/)
      expect(response.body).to include("OPERATIVE")
      expect(response.body).to include("[&gt;] PROFILE")
      expect(response.body).to include("@#{hackr.hackr_alias}")
      expect(response.body).to include("MEMBER SINCE")
      expect(response.body).to include("Ghost in the wire")
      expect(response.body).to include("WIRE PULSES")
      expect(response.body).not_to include("✎ EDIT") # read-only, even for the owner
      expect(response.body).not_to include("Timeline broadcast")
      expect(response.body).not_to include("// BROADCASTS //")

      get "/wire/ghost_alias", headers: {"Turbo-Frame" => "wire-pane"}

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("// NO RECORD //")
    end

    it "keeps the full page for other frame requests (the bio frame following its redirect)" do
      log_in!

      get "/wire/#{hackr.hackr_alias.downcase}", headers: {"Turbo-Frame" => "profile-bio"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="profile-bio"))
      expect(response.body).to include("// BROADCASTS //")
      expect(response.body).not_to include("[&gt;] PROFILE")
    end

    it "shows the bio edit frame only to the profile owner" do
      hackr.update!(bio: "Ghost in the wire")
      log_in!

      get "/wire/#{hackr.hackr_alias.downcase}"
      expect(response.body).to include("✎ EDIT")

      get "/wire/#{other.hackr_alias.downcase}"
      expect(response.body).not_to include("✎ EDIT")
    end
  end

  describe "bio frame" do
    it "updates the bio through the frame form" do
      log_in!

      get "/wire/#{hackr.hackr_alias.downcase}/bio/edit"
      expect(response.body).to include("profile-bio")

      patch "/wire/#{hackr.hackr_alias.downcase}/bio", params: {bio: "Rewired."}
      expect(response).to have_http_status(:see_other) # Turbo frame rule: non-GET must redirect
      expect(response).to redirect_to("/wire/#{hackr.hackr_alias.downcase}")
      expect(hackr.reload.bio).to eq("Rewired.")
    end

    it "rejects editing someone else's bio" do
      log_in!

      patch "/wire/#{other.hackr_alias.downcase}/bio", params: {bio: "hax"}

      expect(response).to have_http_status(:forbidden)
      expect(other.reload.bio).to be_nil
    end

    it "re-renders the form with model errors" do
      log_in!

      patch "/wire/#{hackr.hackr_alias.downcase}/bio", params: {bio: "mail me at x@y.com"}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("can&#39;t contain an email address")
    end
  end

  describe "GET /wire/pulse/:id" do
    it "renders the thread tree" do
      root = make_pulse(other, content: "Thread root pulse")
      reply = create(:pulse, grid_hackr: hackr, content: "Nested reply", parent_pulse_id: root.id)
      create(:pulse, grid_hackr: other, content: "Deep reply", parent_pulse_id: reply.id)
      log_in!

      get "/wire/pulse/#{root.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Thread")
      expect(response.body).to include("3 pulses")
      expect(response.body).to include("Thread root pulse")
      expect(response.body).to include("Nested reply")
      expect(response.body).to include("Deep reply")
    end

    it "resolves a splice to its root thread" do
      root = make_pulse(other, content: "The root")
      reply = create(:pulse, grid_hackr: hackr, content: "The reply", parent_pulse_id: root.id)
      log_in!

      get "/wire/pulse/#{reply.id}"

      expect(response.body).to include("The root")
      expect(response.body).to include("The reply")
    end

    it "404s for unknown pulses — a stub frame for a Turbo-Frame request" do
      log_in!
      get "/wire/pulse/999999"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Pulse not found")

      get "/wire/pulse/999999", headers: {"Turbo-Frame" => "pulse_999999_thread"}

      expect(response).to have_http_status(:not_found)
      expect(response.body).to match(/<turbo-frame[^>]*id="pulse_999999_thread"/)
      expect(response.body).to include("// PULSE NOT FOUND //")
    end

    it "answers a Turbo-Frame request with the thread fragment: replies oldest first, quotes off the root, the reply prompt" do
      root = make_pulse(other, content: "Thread root pulse")
      reply = create(:pulse, grid_hackr: hackr, content: "Nested reply", parent_pulse_id: root.id)
      create(:pulse, grid_hackr: other, content: "Deep reply", parent_pulse_id: reply.id)
      log_in!

      get "/wire/pulse/#{root.id}", headers: {"Turbo-Frame" => "pulse_#{root.id}_thread"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<turbo-frame[^>]*id="pulse_#{root.id}_thread"/)
      expect(response.body).to include(%(id="pulse_#{root.id}_thread_list"))
      expect(response.body).not_to include("Thread root pulse") # the root is the row above the frame
      expect(response.body.index("Nested reply")).to be < response.body.index("Deep reply")
      expect(response.body.scan("wire-quote-mark").length).to eq(1) # only the deep reply quotes a non-root parent
      expect(response.body).to include("Splice into @#{other.hackr_alias}&#39;s thread...")
      expect(response.body).to include(%(id="pulse_#{root.id}_reply_error"))
      expect(response.body).not_to include("site-header")
    end

    it "answers the context pane (frame wire-pane) with the root in full above the same thread fragment" do
      root = make_pulse(other, content: "Paneable root")
      create(:pulse, grid_hackr: hackr, content: "Pane reply", parent_pulse_id: root.id)
      log_in!

      get "/wire/pulse/#{root.id}", headers: {"Turbo-Frame" => "wire-pane"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<turbo-frame[^>]*id="wire-pane"/)
      expect(response.body).to include("wire-pane-head")
      expect(response.body).to include("##{root.id} · 2 PULSES")
      expect(response.body).to include("[&gt;] PAGE")
      expect(response.body).to include("Paneable root") # the pane shows the root itself…
      expect(response.body).not_to include(%(id="pulse_#{root.id}")) # …without the feed row's ids
      expect(response.body).to include(%(id="pulse_#{root.id}_thread_list"))
      expect(response.body).to include("Pane reply")
      expect(response.body).to include("Splice into @#{other.hackr_alias}&#39;s thread...")
      expect(response.body).not_to include("site-header")
    end

    it "shows a dropped root as dropped in the pane, without a prompt" do
      root = make_pulse(other, content: "Doomed root")
      create(:pulse, grid_hackr: hackr, content: "Its reply", parent_pulse_id: root.id)
      root.pulse_drop!
      log_in!

      get "/wire/pulse/#{root.id}", headers: {"Turbo-Frame" => "wire-pane"}

      expect(response.body).to include("[ PULSE DROPPED BY GOVCORP ]")
      expect(response.body).not_to include("Doomed root")
      expect(response.body).to include("Its reply")
      expect(response.body).not_to include("wire-prompt-input")
    end
  end
end
