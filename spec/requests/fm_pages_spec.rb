require "rails_helper"

RSpec.describe "FM pages", type: :request do
  let(:artist) { create(:artist, name: "Test Artist") }

  describe "GET /fm" do
    it "renders the landing as a console screen with the lore and the latest releases as tiles" do
      older = create(:release, :with_cover, artist: artist, name: "Grid Runner", label: "hackr.fm", release_date: Date.new(2025, 1, 1))
      newer = create(:release, :with_cover, artist: artist, name: "Neon Transmission", label: "hackr.fm", release_date: Date.new(2026, 1, 1))
      create(:track, artist: artist, release: newer)

      get "/fm"

      expect(response).to have_http_status(:success)
      body = response.body
      expect(body).to include('class="console console--fm" data-controller="terminal" data-boot="pending"')
      expect(body).not_to include("chrome-ascii")
      expect(body).not_to include("tui-window")
      expect(body).not_to include('style="')
      expect(body).to include("HACKR.FM", "[&gt;] RADIO", "[&gt;] VAULT", "● ON AIR")
      expect(body).to include("hackr.fm opened as a frequency", "// THE FREQUENCY //", "// LATEST RELEASES //")
      expect(body).to include("[01]", "[02]")
      expect(body.index("Neon Transmission")).to be < body.index("Grid Runner")
      expect(body).to include(%(data-command="01" href="/#{artist.slug}/releases/#{newer.slug}"))
      expect(body).to include(%(data-command="02" href="/#{artist.slug}/releases/#{older.slug}"))
      expect(body).to include("fm-cover-img", "data-peek-src-value")
      expect(body).to include("ALBUM · 2026-01-01 · 1 track")
    end

    it "counts uncovered and off-label releases correctly in the status rows" do
      create(:release, :with_cover, artist: artist, name: "On Label", label: "hackr.fm")
      create(:release, artist: artist, name: "No Cover", label: "hackr.fm")
      create(:release, :with_cover, artist: artist, name: "Off Label", label: "Other Records")
      create(:artist, name: "Roster Band", artist_type: "band")

      get "/fm"

      body = response.body
      expect(body).to include("On Label")
      expect(body).not_to include("Off Label")
      expect(body).not_to include("No Cover")
      expect(body).to include(%(<a class="console-link" href="/fm/releases">2 releases</a>))
      expect(body).to include(%(<a class="console-link" href="/f/net">2 on the network</a>))
      expect(body).to include("NONE SCHEDULED")
      expect(body).not_to include("// TRANSMISSION INCOMING //")
    end

    it "renders incoming tiles with the animated cover, locking those beyond the first four" do
      5.times do |i|
        create(:release, :with_cover, artist: artist, name: "Incoming #{i + 1}",
          coming_soon: true, release_date: Date.current + i.days)
      end

      get "/fm"

      body = response.body
      (1..5).each { |i| expect(body).to include("Incoming #{i}") }
      expect(body).to include("5 pending transmission", "PENDING TRANSMISSION")
      expect(body).to include("// TRANSMISSION INCOMING //", "click->signal-code#signalClicked")
      expect(body).to include('data-signal-code-target="modal"', 'data-signal-code-target="input"')
      expect(body.scan("fm-cover--incoming").size).to eq(5)
      expect(body.scan("fm-soon-badge").size).to eq(5)
      expect(body).not_to include("data-peek-src-value")
      expect(body.scan("fm-locked").size).to eq(1)
      expect(body).to include('class="fm-tile console-line fm-locked" hidden="hidden"')
      expect(body).to include("(01 02 03 04)")
    end

    it "lists the destinations as prompt commands, playlists only for a logged-in hackr" do
      get "/fm"

      %w[radio releases vault fnet home].each { |cmd| expect(response.body).to include(%(data-command="#{cmd}")) }
      expect(response.body).not_to include('data-command="playlists"')
      expect(response.body).to include("(radio releases vault fnet home)")
    end
  end

  describe "GET /fm/releases" do
    it "renders the hackr.fm catalog as numbered tiles" do
      create(:release, :with_cover, artist: artist, name: "Catalog One", label: "hackr.fm",
        catalog_number: "HFM-001", release_date: Date.new(2026, 2, 1))
      two = create(:release, artist: artist, name: "Catalog Two", label: "hackr.fm", release_date: Date.new(2025, 2, 1))

      get "/fm/releases"

      expect(response).to have_http_status(:success)
      body = response.body
      expect(body).to include('class="console console--fm"')
      expect(body).not_to include("tui-window")
      expect(body).not_to include('style="')
      expect(body).to include("[&lt;] FM", "[&gt;] VAULT", "// CATALOG //")
      expect(body).to include("2 releases", "1 artist")
      expect(body).to include("Catalog One", "HFM-001", "Catalog Two", "Test Artist")
      expect(body).to include(%(data-command="02" href="/#{artist.slug}/releases/#{two.slug}"))
      expect(body).to include("fm-cover-none")
      expect(body).to include("(01 02)", %(data-command="fm"))
    end

    it "says so when the label has nothing cataloged" do
      get "/fm/releases"

      expect(response.body).to include("NO RELEASES CATALOGED YET", "NONE CATALOGED")
    end
  end
end
