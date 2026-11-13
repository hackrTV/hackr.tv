require "rails_helper"

RSpec.describe "Bands page", type: :request do
  describe "GET /f/net" do
    it "renders the roster as a console screen of numbered band tiles" do
      synthia = create(:artist, name: "Synthia", slug: "synthia", artist_type: "band", genre: "Synth Pop")
      create(:artist, name: "fresh Signal", slug: "fresh-signal", artist_type: "band")
      create(:track, artist: synthia, release: create(:release, artist: synthia))

      get "/f/net"

      expect(response).to have_http_status(:success)
      body = response.body
      expect(body).to include('class="console console--fnet" data-controller="terminal" data-boot="pending"')
      expect(body).not_to include("chrome-ascii")
      expect(body).not_to include("tui-window")
      expect(body).not_to include('style="')
      expect(body).to include("FRACTURE NETWORK", "THE ROSTER · 2 ARTISTS BROADCASTING", "// ROSTER //")
      expect(body).to include("2 artists", "1 track")
      # Case-insensitive name order: fresh Signal before Synthia.
      expect(body).to include(%(data-command="01" href="/fresh-signal/releases">fresh Signal</a>))
      expect(body).to include(%(data-command="02" href="/synthia/releases">Synthia</a>))
      # Curated description for a known slug, fallback line for the rest.
      expect(body).to include("Unbound AI singing through time")
      expect(body).to include("Broadcasting truth through sound.")
      expect(body).to include("SYNTH POP", "1 track · 1 release")
      expect(body).to include("// ABOUT THE FRACTURE NETWORK //", "the signal continues.")
      expect(body).to include("(01 02)", "(fm releases vault home)")
    end

    it "lists positioned bands first, in position order, ahead of the alphabetical rest" do
      create(:artist, name: "Alpha Band", slug: "alpha-band", artist_type: "band")
      create(:artist, name: "Zulu Band", slug: "zulu-band", artist_type: "band", position: 2)
      create(:artist, name: "Yankee Band", slug: "yankee-band", artist_type: "band", position: 1)

      get "/f/net"

      body = response.body
      expect(body).to include(%(data-command="01" href="/yankee-band/releases">Yankee Band</a>))
      expect(body).to include(%(data-command="02" href="/zulu-band/releases">Zulu Band</a>))
      expect(body).to include(%(data-command="03" href="/alpha-band/releases">Alpha Band</a>))
    end

    it "links a band with a profile page to it, and one without to its releases" do
      create(:artist, name: "System Rot", slug: "system-rot", artist_type: "band")
      create(:artist, name: "Unprofiled", slug: "unprofiled", artist_type: "band")

      get "/f/net"

      body = response.body
      expect(body).to include(%(data-command="01" href="/system-rot">System Rot</a>))
      expect(body).to include(%(<a class="console-bar-link" href="/system-rot">[&gt;] PROFILE</a>))
      expect(body).to include(%(<a class="console-bar-link" href="/system-rot/releases">[&gt;] RELEASES</a>))
      expect(body).to include(%(data-command="02" href="/unprofiled/releases">Unprofiled</a>))
      expect(body).to include("PROFILE COMING SOON")
      expect(body).to include(%(<a class="console-bar-link" href="/unprofiled/releases">[&gt;] RELEASES</a>))

      get "/unprofiled/releases"
      expect(response).to have_http_status(:success)
    end

    it "shows the band's newest released cover, skipping incoming and vault-hidden releases" do
      band = create(:artist, name: "Cover Band", artist_type: "band")
      create(:release, :with_cover, artist: band, slug: "old", release_date: Date.new(2024, 1, 1))
      hidden = create(:release, :with_cover, artist: band, slug: "hidden", release_date: Date.new(2026, 1, 1))
      create(:track, artist: band, release: hidden, show_in_pulse_vault: false)
      create(:release, :with_cover, artist: band, slug: "soon", coming_soon: true, release_date: Date.new(2027, 1, 1))
      create(:artist, name: "Bare Band", artist_type: "band")

      get "/f/net"

      body = response.body
      expect(body.scan("fm-cover-img").size).to eq(1)
      expect(body.scan("fm-cover-none").size).to eq(1)
      expect(body).to include("data-peek-src-value")
      # The hidden release's track is not counted either.
      expect(body).to include("0 tracks · 1 release")
    end

    it "only lists band-type artists" do
      create(:artist, name: "Roster Band", artist_type: "band")
      create(:artist, name: "Score Only", artist_type: "ost")

      get "/f/net"

      expect(response.body).to include("Roster Band")
      expect(response.body).not_to include("Score Only")
    end

    it "says so when the network is empty" do
      get "/f/net"

      expect(response.body).to include("NO ARTISTS ON THE NETWORK YET")
    end
  end
end
