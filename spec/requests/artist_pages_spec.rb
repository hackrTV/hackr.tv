require "rails_helper"

# Phase 4: bespoke artist pages (replaces the six standalone React pages
# under components/pages/artist/). Paths are wired to
# ArtistPagesController right after this task lands.
RSpec.describe "Artist pages", type: :request do
  describe "GET /thecyberpulse" do
    it "renders the landing page" do
      get "/thecyberpulse"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("TRANSMISSION ORIGIN &amp; BROADCAST HUB")
      expect(response.body).to include("You found the frequency. Everything else is below.")
      expect(response.body).to include("/thecyberpulse/bio")
      expect(response.body).to include("/thecyberpulse/releases")
      expect(response.body).to include("/thecyberpulse/vidz")
    end
  end

  describe "GET /thecyberpulse/bio" do
    it "renders the bio with the latest VOD embed and bio-credit hook" do
      artist = create(:artist, :thecyberpulse)
      create(:hackr_stream, artist: artist, title: "Old Operation",
        vod_url: "https://www.youtube.com/watch?v=aaaaaaaaaaa", started_at: 3.days.ago)
      create(:hackr_stream, artist: artist, title: "Latest Operation",
        vod_url: "https://youtu.be/dQw4w9WgXcQ", started_at: 1.day.ago)

      get "/thecyberpulse/bio"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("[:: SIGNAL INCOMING ::]")
      expect(response.body).to include("RYKER M. PULSE")
      expect(response.body).to include("youtube-nocookie.com/embed/dQw4w9WgXcQ")
      expect(response.body).not_to include("embed/aaaaaaaaaaa")
      expect(response.body).to include("Latest Operation")
      expect(response.body).to include('data-controller="bio-credit"')
      expect(response.body).to include('data-bio-credit-slug-value="thecyberpulse"')
    end
  end

  describe "GET /xeraen" do
    it "renders the console landing with the catalog in its status block" do
      artist = create(:artist, :xeraen)
      older = create(:release, :ep, artist: artist, name: "XORDIUM", slug: "xordium", release_date: Date.new(2124, 10, 17))
      create(:track, :with_audio, artist: artist, release: older)
      latest = create(:release, :single, artist: artist, name: "Encrypted Shroud", slug: "encrypted-shroud", release_date: Date.new(2125, 7, 19))
      create(:track, :with_audio, artist: artist, release: latest)
      hidden = create(:release, artist: artist, name: "Hidden Cut", slug: "hidden-cut", release_date: Date.new(2126, 1, 1))
      create(:track, :with_audio, artist: artist, release: hidden, show_in_pulse_vault: false)
      create(:release, :single, artist: artist, name: "Refocus", slug: "refocus", coming_soon: true, release_date: Date.new(2126, 8, 9))

      get "/xeraen"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include('class="console console--xeraen"')
      expect(response.body).to include('data-controller="terminal"')
      expect(response.body).to include('data-boot="pending"')
      expect(response.body).not_to include("chrome-ascii") # a console screen, like the WIRE
      expect(response.body).to include("OMNIWAVE GENESIS VECTOR")
      expect(response.body).to include("● TRANSMITTING")
      expect(response.body).to include("2 cataloged")
      expect(response.body).to include("Encrypted Shroud")
      expect(response.body).to include("2125-07-19")
      expect(response.body).to include("/xeraen/releases/encrypted-shroud")
      expect(response.body).not_to include("Hidden Cut") # all-vault-hidden releases stay out, like the catalog
      expect(response.body).to include("INCOMING")
      expect(response.body).to include("Refocus")
      expect(response.body).to include("If you're hearing this, the signal is still reaching you.")
      expect(response.body).to include("// DESTINATIONS //")
      expect(response.body).to include('data-command="bio"')
      expect(response.body).to include('data-command="releases"')
      expect(response.body).not_to include('data-command="xeraen"') # the page itself is left out
      expect(response.body).to include("/xeraen/bio")
      expect(response.body).to include("/xeraen/releases")
      expect(response.body).to include('class="console-input"')
    end

    it "renders with no artist row or releases" do
      get "/xeraen"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("NONE CATALOGED")
      expect(response.body).not_to include("INCOMING")
    end
  end

  describe "GET /xeraen/bio" do
    it "renders the bio console with the latest featured track on the player contract" do
      artist = create(:artist, :xeraen)
      older = create(:release, artist: artist, release_date: 2.years.ago.to_date)
      newer = create(:release, artist: artist, release_date: 1.month.ago.to_date)
      create(:track, :with_audio, artist: artist, release: older, title: "Early Fury", featured: true)
      latest = create(:track, :with_audio, artist: artist, release: newer, title: "Omniwave Apex", featured: true)
      create(:track, :with_audio, artist: artist, release: newer, title: "Unfeatured Cut")

      get "/xeraen/bio"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include('data-controller="terminal bio-credit"')
      expect(response.body).to include('data-boot="done"') # no line reveal on the long page
      expect(response.body).to include('data-terminal-autofocus-value="false"')
      expect(response.body).not_to include("chrome-ascii")
      expect(response.body).to include("// FIRST CONTACT //")
      expect(response.body).to include("// LATEST TRANSMISSION //")
      expect(response.body).to include("// SOLO TRANSMISSIONS //")
      expect(response.body).to include("// THE PARADOX OF PRESENCE //")
      expect(response.body).to include("TEMPORAL STATUS")
      expect(response.body).to include("Omniwave Apex")
      expect(response.body).not_to include("Early Fury")
      expect(response.body).not_to include("Unfeatured Cut")
      expect(response.body).to include("data-player-id=\"#{latest.id}\"")
      expect(response.body).to include("data-player-url=")
      expect(response.body).to include('data-controller="track-list"')
      expect(response.body).to include("► PLAY")
      expect(response.body).to include('data-bio-credit-slug-value="xeraen"')
      expect(response.body).to include('data-command="xeraen"')
      expect(response.body).not_to include('data-command="bio"')
      expect(response.body).to include("[&lt;] XERAEN")
    end

    it "tunes when no featured track exists" do
      create(:artist, :xeraen)

      get "/xeraen/bio"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("[TUNING SIGNAL...]")
      expect(response.body).not_to include('data-controller="track-list"')
    end
  end

  describe "GET /sector/x" do
    it "renders the coming-soon page" do
      get "/sector/x"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("[:: COMING SOON ::]")
      expect(response.body).to include("Keep your hackr eyes peeled!")
    end
  end

  describe "GET /wavelength-zero" do
    it "renders the manifesto page" do
      get "/wavelength-zero"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("WAVELENGTH ZERO")
      expect(response.body).to include("When was the last time you felt something real?")
      expect(response.body).to include('data-bio-credit-slug-value="wavelength-zero"')
      expect(response.body).to include("/wavelength-zero/releases")
    end
  end
end
