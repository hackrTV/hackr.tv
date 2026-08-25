require "rails_helper"

# Server-rendered PulseWire pages + form endpoints (Hotwire migration
# Phase 3). The JSON API keeps its own specs.
RSpec.describe "Wire pages", type: :request do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }
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

    it "shows the login prompt when anonymous" do
      get "/wire"

      expect(response.body).to include("to broadcast on the WIRE")
      expect(response.body).not_to include("Broadcast on the WIRE...")
    end

    it "renders the empty state" do
      get "/wire"

      expect(response.body).to include("The WIRE is silent. Broadcast the first pulse.")
    end

    it "excludes signal-dropped and splice pulses from the feed" do
      make_pulse(other, content: "Visible pulse")
      dropped = make_pulse(other, content: "Dropped pulse")
      dropped.signal_drop!
      root = make_pulse(other, content: "Thread root")
      create(:pulse, grid_hackr: hackr, content: "A reply", parent_pulse_id: root.id)

      get "/wire"

      expect(response.body).to include("Visible pulse")
      expect(response.body).not_to include("Dropped pulse")
      expect(response.body).not_to include("A reply")
    end

    it "paginates via a lazy frame" do
      55.times { |i| make_pulse(other, content: "Pulse number #{i}") }

      get "/wire"
      expect(response.body).to include("wire-page-2")

      get "/wire", params: {page: 2}
      expect(response.body).to include("End of the WIRE")
    end

    it "renders censored links for non-admin posters and live links for admins" do
      make_pulse(other, content: "see https://example.com now")
      admin = create(:grid_hackr, :admin, password: "hackthegrid")
      make_pulse(admin, content: "read https://example.com today")

      get "/wire"

      expect(response.body).to include("[LINK CENSORED BY GOVCORP]")
      expect(response.body).to include('<a href="https://example.com"')
    end
  end

  describe "POST /wire/pulses" do
    it "requires login" do
      post "/wire/pulses", params: {content: "nope"}

      expect(response).to redirect_to("/grid/login")
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

    it "renders the composer error for invalid content" do
      log_in!

      post "/wire/pulses", params: {content: "x" * 300},
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("composer-error")
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

      get "/wire/#{hackr.hackr_alias.downcase}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@#{hackr.hackr_alias}")
      expect(response.body).to include("MEMBER SINCE")
      expect(response.body).to include("WIRE PULSES")
      expect(response.body).to include("📌 PINNED")
      expect(response.body).to include("Pinned broadcast")
      expect(response.body).to include("Profile broadcast")
      expect(response.body).to include("echoed") # echo indicator
      expect(response.body).to include("Echoed by profile owner")
      expect(response.body.scan("Pinned broadcast").length).to eq(1) # dedup vs timeline
      expect(pulse).to be_present
    end

    it "canonicalizes case via the LowercaseRedirect middleware" do
      get "/wire/#{hackr.hackr_alias.upcase}"

      expect(response).to have_http_status(:moved_permanently)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@#{hackr.hackr_alias}")
    end

    it "renders NO SIGNAL for unknown hackrs" do
      get "/wire/ghost_alias"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("NO SIGNAL")
      expect(response.body).to include("@ghost_alias")
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

      get "/wire/pulse/#{reply.id}"

      expect(response.body).to include("The root")
      expect(response.body).to include("The reply")
    end

    it "404s for unknown pulses" do
      get "/wire/pulse/999999"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Pulse not found")
    end
  end
end
