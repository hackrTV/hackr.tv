require "rails_helper"

# Phase 4: Hotwire artist catalog (replaces ReleaseListPage.tsx,
# ReleaseDetailPage.tsx, TrackDetailPage.tsx, VodzPage.tsx and
# VodzShowPage.tsx). Written against the final paths — routes are wired
# separately, so these fail with routing errors until then.
RSpec.describe "Artist catalog pages", type: :request do
  let(:artist) { create(:artist, :thecyberpulse) }
  let(:release) { create(:release, artist: artist, name: "Neon Signals") }

  describe "GET /:artist_slug/releases" do
    it "renders the artist's releases with coming-soon cards first" do
      create(:track, :with_audio, artist: artist, release: release)
      soon = create(:release, artist: artist, coming_soon: true, name: "Ghost Frequency")

      get "/thecyberpulse/releases"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("The.CyberPul.se :: RELEASES")
      expect(response.body).to include("Neon Signals")
      expect(response.body).to include("Ghost Frequency")
      expect(response.body).to include("INCOMING")
      expect(response.body.index("Ghost Frequency")).to be < response.body.index("Neon Signals")
      expect(response.body).to include("/thecyberpulse/releases/#{release.slug}")
      expect(response.body).to include("/thecyberpulse/releases/#{soon.slug}")
    end

    it "hides releases whose tracks are all hidden from the vault" do
      create(:track, artist: artist, release: release, show_in_pulse_vault: false)
      visible = create(:release, artist: artist, name: "Visible Signals")
      create(:track, artist: artist, release: visible)

      get "/thecyberpulse/releases"

      expect(response.body).to include("Visible Signals")
      expect(response.body).not_to include("Neon Signals")
    end

    it "renders the empty state for an artist with no releases" do
      artist

      get "/thecyberpulse/releases"

      expect(response.body).to include("No releases cataloged yet.")
      expect(response.body).to include("THECYBERPULSE :: RELEASES")
    end
  end

  describe "GET /:artist_slug/releases/:id" do
    it "renders the tracklist with playable player-row attributes" do
      track = create(:track, :with_audio, artist: artist, release: release, title: "Neon Drift")
      create(:track, artist: artist, release: release, title: "Silent Cut", track_number: 2)

      get "/thecyberpulse/releases/#{release.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("NEON SIGNALS")
      expect(response.body).to include("TRACKLIST")
      expect(response.body).to include('data-controller="track-list"')
      expect(response.body).to include("data-player-id=\"#{track.id}\"")
      expect(response.body).to include("data-player-url=")
      expect(response.body).to include("data-player-artist=\"The.CyberPul.se\"")
      expect(response.body).to include("Neon Drift")
      expect(response.body).to include("/thecyberpulse/trackz/#{track.slug}")
      # Track without audio renders, but carries no player URL.
      expect(response.body).to include("Silent Cut")
      expect(response.body).to include("Disc length")
      expect(response.body).to include("STREAMING FREQUENCIES")
    end

    it "renders the COMING SOON state for a coming-soon release" do
      soon = create(:release, artist: artist, coming_soon: true, name: "Ghost Frequency")
      create(:track, :with_audio, artist: artist, release: soon, title: "Hidden Anthem")

      get "/thecyberpulse/releases/#{soon.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("SIGNAL INCOMING — TRANSMISSION PENDING")
      expect(response.body).to include("TRACKLIST [ENCRYPTED]")
      expect(response.body).to include("[SIGNAL ENCRYPTED]")
      expect(response.body).to include("PENDING TRANSMISSION")
      expect(response.body).to include("FREQUENCIES NOT YET ALLOCATED")
      # Real track data stays out of the DOM entirely.
      expect(response.body).not_to include("Hidden Anthem")
      expect(response.body).not_to include("data-player-url=")
    end

    it "renders SIGNAL LOST with 404 for unknown releases" do
      artist

      get "/thecyberpulse/releases/does-not-exist"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("SIGNAL LOST")
      expect(response.body).to include("Release not found.")
    end

    it "renders SIGNAL LOST for releases hidden from the vault" do
      create(:track, artist: artist, release: release, show_in_pulse_vault: false)

      get "/thecyberpulse/releases/#{release.slug}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("SIGNAL LOST")
    end
  end

  # The catalog console (2026-10-29): a prototype on XERAEN only —
  # ArtistCatalogController::CONSOLE_CATALOG_SLUGS swaps the templates;
  # the other slugs keep the card grid / fieldset stack above.
  describe "XERAEN catalog console" do
    let(:xeraen) { create(:artist, :xeraen) }

    it "renders /xeraen/releases as a ledger — incoming first, numbered rows, no card grid" do
      ep = create(:release, :ep, artist: xeraen, name: "XORDIUM", slug: "xordium", release_date: Date.new(2124, 10, 17))
      create(:track, :with_audio, artist: xeraen, release: ep, title: "XORDIUM", duration: "2:44")
      create(:track, artist: xeraen, release: ep, title: "Settle The Score", track_number: 2, duration: "2:41")
      soon = create(:release, :single, artist: xeraen, coming_soon: true, name: "Refocus", slug: "refocus")
      create(:track, artist: xeraen, release: soon, title: "Hidden Anthem")
      hidden = create(:release, artist: xeraen, name: "Ghost Record")
      create(:track, artist: xeraen, release: hidden, show_in_pulse_vault: false)

      get "/xeraen/releases"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="console console--xeraen cc-index"')
      expect(response.body).not_to include("chrome-ascii")
      expect(response.body).not_to include("release-list-grid")
      expect(response.body).to include("// INCOMING //")
      expect(response.body).to include("// CATALOG //")
      expect(response.body).to include('data-command="01" href="/xeraen/releases/refocus"') # incoming leads
      expect(response.body).to include('data-command="02" href="/xeraen/releases/xordium"')
      expect(response.body).to include("/xeraen/releases/xordium")
      expect(response.body).to include("EP · 2124-10-17 · 2 tracks · 5:25")
      expect(response.body).to include("PENDING TRANSMISSION</span> · 1 track")
      expect(response.body).not_to include("Ghost Record")
      expect(response.body).to include("1 release")
      expect(response.body).to include('data-command="xeraen"')
      expect(response.body).not_to include('data-command="releases"') # the page's own tag
      expect(response.body).to include('class="console-input"')
    end

    it "renders the empty ledger when nothing is cataloged" do
      xeraen

      get "/xeraen/releases"

      expect(response.body).to include("NONE CATALOGED")
      expect(response.body).to include("NO RELEASES CATALOGED YET")
    end

    it "renders /xeraen/releases/:slug as a console screen on the player row contract" do
      ep = create(:release, :ep, artist: xeraen, name: "XORDIUM", slug: "xordium", release_date: Date.new(2124, 10, 17),
        label: "hackr.fm", streaming_links: {"spotify" => "https://open.spotify.com/album/1", "youtube" => "https://www.youtube.com/playlist?list=1"})
      track = create(:track, :with_audio, artist: xeraen, release: ep, title: "Power To The Hackrs", duration: "2:46")
      create(:track, artist: xeraen, release: ep, title: "Settle The Score", track_number: 2, duration: "2:41")

      get "/xeraen/releases/xordium"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="console console--xeraen cc-release"')
      expect(response.body).not_to include("release-detail-window")
      expect(response.body).to include('<h1 class="console-bar-title">XORDIUM</h1>')
      expect(response.body).to include("RELEASED")
      expect(response.body).to include("2124-10-17")
      expect(response.body).to include("hackr.fm")
      expect(response.body).to include("5:27") # disc length
      expect(response.body).to include("// TRACKS //")
      expect(response.body).to include('data-controller="track-list"')
      expect(response.body).to include("data-player-id=\"#{track.id}\"")
      expect(response.body).to include("data-player-url=")
      expect(response.body).to include("► PLAY")
      expect(response.body).to include("NO AUDIO") # the track without audio
      expect(response.body).to include("href=\"/xeraen/trackz/#{track.slug}\"")
      expect(response.body).to include('data-command="01"')
      expect(response.body).to include("// FREQUENCIES //")
      expect(response.body).to include("[LISTEN]")
      expect(response.body).to include("[YT]")
      expect(response.body).to include("[SP]")
      expect(response.body).to include("Spotify ↗")
      expect(response.body).to include("open.spotify.com")
      expect(response.body).to include('data-command="releases"')
    end

    it "masks a coming-soon release" do
      soon = create(:release, :single, artist: xeraen, coming_soon: true, name: "Refocus", slug: "refocus")
      create(:track, :with_audio, artist: xeraen, release: soon, title: "Hidden Anthem")

      get "/xeraen/releases/refocus"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("◌ SIGNAL INCOMING")
      expect(response.body).to include("PENDING TRANSMISSION")
      expect(response.body).to include("// TRACKS · ENCRYPTED //")
      expect(response.body).to include("[SIGNAL ENCRYPTED]")
      expect(response.body).to include("NOT YET ALLOCATED")
      expect(response.body).not_to include("Hidden Anthem")
      expect(response.body).not_to include("data-player-url=")
    end

    it "renders SIGNAL LOST as a console screen with 404 for unknown and vault-hidden releases" do
      hidden = create(:release, artist: xeraen, name: "Ghost Record")
      create(:track, artist: xeraen, release: hidden, show_in_pulse_vault: false)

      get "/xeraen/releases/does-not-exist"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("// SIGNAL LOST //")
      expect(response.body).to include("Release not found.")
      expect(response.body).to include('class="console console--xeraen cc-release"')

      get "/xeraen/releases/#{hidden.slug}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("// SIGNAL LOST //")
    end

    it "resolves a numeric id too" do
      ep = create(:release, artist: xeraen, name: "XORDIUM")
      create(:track, artist: xeraen, release: ep)

      get "/xeraen/releases/#{ep.id}"

      expect(response.body).to include('<h1 class="console-bar-title">XORDIUM</h1>')
    end

    it "renders /xeraen/trackz/:slug as a console screen on the player row contract" do
      ep = create(:release, :ep, artist: xeraen, name: "XORDIUM", slug: "xordium", release_date: Date.new(2124, 10, 17))
      track = create(:track, :with_audio, :featured, artist: xeraen, release: ep, title: "Power To The Hackrs", track_number: 2, duration: "2:46", release_date: Date.new(2124, 10, 17),
        lyrics: "In the streets we raise our might\nUnity our call tonight",
        streaming_links: {"spotify" => "https://open.spotify.com/track/1", "youtube" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ"})
      create(:track, artist: xeraen, release: ep, title: "XORDIUM", track_number: 1, duration: "2:44")
      sibling = create(:track, artist: xeraen, release: ep, title: "Settle The Score", track_number: 3, duration: "2:41")
      vod = create(:hackr_stream, artist: xeraen, track_slug: track.slug, title: "Chaddin Session",
        vod_url: "https://www.youtube.com/embed/dQw4w9WgXcQ")

      get "/xeraen/trackz/#{track.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="console console--xeraen cc-track-page"')
      expect(response.body).not_to include("track-detail-window")
      expect(response.body).not_to include("TRACK INFO")
      expect(response.body).to include('<h1 class="console-bar-title">Power To The Hackrs</h1>')
      expect(response.body).to include("XERAEN · TRACK 02")
      expect(response.body).to include("★ FEATURED")
      expect(response.body).to include("[&lt;] XORDIUM")
      expect(response.body).to include('02 <span class="console-dim">of 03</span>')
      expect(response.body).to include("2124-10-17")
      expect(response.body).to include("// TRANSMISSION //")
      expect(response.body).to include('data-controller="track-list"')
      expect(response.body).to include("data-player-url=")
      expect(response.body).to include("► PLAY")
      expect(response.body).to include("[▶ VIDEO]")
      expect(response.body).to include("// DECODED LYRICS //")
      expect(response.body).to include("In the streets we raise our might<br>")
      expect(response.body).to include("[LISTEN]")
      expect(response.body).to include("[SP]")
      expect(response.body).to include("Spotify ↗")
      expect(response.body).to include("open.spotify.com")
      expect(response.body).to include("[VOD]")
      expect(response.body).to include("href=\"/thecyberpulse/vidz/#{vod.id}\"")
      expect(response.body).to include("Chaddin Session")
      expect(response.body).to include("// ALSO ON XORDIUM //")
      expect(response.body).to include('data-command="01"')
      expect(response.body).to include("data-command=\"03\" href=\"/xeraen/trackz/#{sibling.slug}\"")
      expect(response.body).not_to include('data-command="02"') # the page's own track is not a sibling row
      expect(response.body).to include("// END OF TRANSMISSION //")
      expect(response.body).to include('data-command="releases"')
      expect(response.body).to include('class="console-input"')
    end

    it "reads NO AUDIO for an untimed stub on a single and skips the empty sections" do
      single = create(:release, :single, artist: xeraen, name: "Encrypted Shroud", slug: "encrypted-shroud")
      track = create(:track, :without_lyrics, artist: xeraen, release: single, title: "Encrypted Shroud", duration: nil, streaming_links: {})
      create(:hackr_stream, artist: xeraen, track_slug: track.slug, title: "Dry Run") # no vod_url: no [VOD] row, no [▶ VIDEO]

      get "/xeraen/trackz/#{track.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("NO AUDIO ON FILE")
      expect(response.body).to include(">NO AUDIO<")
      expect(response.body).not_to include('class="play-track-btn cc-play"')
      expect(response.body).not_to include("// DECODED LYRICS //")
      expect(response.body).not_to include("// ALSO ON")
      expect(response.body).not_to include("[VOD]")
      expect(response.body).not_to include("[▶ VIDEO]")
      expect(response.body).not_to include("Dry Run")
      expect(response.body).to include('01 <span class="console-dim">of 01</span>')
      expect(response.body).to include("[LISTEN]")
      expect(response.body).not_to include("type a track number")
    end

    it "keeps the coming-soon redirect and renders SIGNAL LOST as a console screen with 404" do
      soon = create(:release, artist: xeraen, coming_soon: true, slug: "refocus")
      track = create(:track, artist: xeraen, release: soon)

      get "/xeraen/trackz/#{track.slug}"

      expect(response).to redirect_to("/xeraen/releases/refocus")

      get "/xeraen/trackz/does-not-exist"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("// SIGNAL LOST //")
      expect(response.body).to include("Track frequency not found.")
      expect(response.body).to include('class="console console--xeraen cc-track-page"')
      expect(response.body).not_to include("track-detail-window")
    end

    it "leaves the other slugs on the shared catalog" do
      create(:track, artist: artist, release: release)

      get "/thecyberpulse/releases"

      expect(response.body).to include("release-list-grid")
      expect(response.body).not_to include("cc-index")
    end
  end

  describe "GET /:artist_slug/trackz/:id" do
    it "renders the track with lyrics and streaming links sections" do
      track = create(:track, :with_audio, artist: artist, release: release, title: "Neon Drift",
        lyrics: "Static hums in the wires", duration: "3:45")

      get "/thecyberpulse/trackz/#{track.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("NEON DRIFT")
      expect(response.body).to include("TRACK INFO")
      expect(response.body).to include("DECODED LYRICS")
      expect(response.body).to include("Static hums in the wires")
      expect(response.body).to include("→ Spotify")
      expect(response.body).to include("→ YouTube")
      expect(response.body).to include("▶ PULSE VAULT")
      expect(response.body).to include('data-controller="track-list"')
      expect(response.body).to include("data-player-url=")
      expect(response.body).to include("► PLAY")
      expect(response.body).to include("ALL TRACKS IN PULSE VAULT →")
    end

    it "redirects coming-soon tracks to their release page" do
      soon = create(:release, artist: artist, coming_soon: true)
      track = create(:track, artist: artist, release: soon)

      get "/thecyberpulse/trackz/#{track.slug}"

      expect(response).to redirect_to("/thecyberpulse/releases/#{soon.slug}")
    end

    it "renders SIGNAL LOST with 404 for unknown tracks" do
      artist

      get "/thecyberpulse/trackz/does-not-exist"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("SIGNAL LOST")
      expect(response.body).to include("Track frequency not found.")
    end
  end

  describe "GET /thecyberpulse/vidz" do
    it "lists VODs with livestream badges and hides streams without a VOD" do
      create(:hackr_stream, :livestream_with_vod, artist: artist, title: "Broadcast One")
      create(:hackr_stream, artist: artist, title: "No VOD Yet")

      get "/thecyberpulse/vidz"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("The.CyberPul.se :: VIDZ")
      expect(response.body).to include("Broadcast One")
      expect(response.body).to include("Livestream")
      expect(response.body).not_to include("No VOD Yet")
    end

    it "renders the empty state when the artist has no VODs" do
      artist

      get "/thecyberpulse/vidz"

      expect(response.body).to include("No videos available yet.")
    end

    it "lists XERAEN's recordings in the archive, not other artists'" do
      artist
      create(:hackr_stream, :with_vod, artist: create(:artist, :xeraen), title: "Chaddin Session")
      create(:hackr_stream, :with_vod, artist: create(:artist), title: "Guest Set")

      get "/thecyberpulse/vidz"

      expect(response.body).to include("The.CyberPul.se :: VIDZ")
      expect(response.body).to include("Chaddin Session")
      expect(response.body).not_to include("Guest Set")
    end
  end

  describe "GET /xeraen/vidz" do
    it "redirects to thecyberpulse when XERAEN has no VODs" do
      create(:artist, :xeraen)

      get "/xeraen/vidz"

      expect(response).to redirect_to("/thecyberpulse/vidz")
    end
  end

  describe "GET /thecyberpulse/vidz/:id" do
    it "renders the click-to-play player wired for the watch credit" do
      stream = create(:hackr_stream, artist: artist, title: "Broadcast One",
        vod_url: "https://www.youtube.com/embed/dQw4w9WgXcQ")

      get "/thecyberpulse/vidz/#{stream.id}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Broadcast One")
      expect(response.body).to include('data-controller="vod-player"')
      expect(response.body).to include('data-vod-player-video-id-value="dQw4w9WgXcQ"')
      expect(response.body).to include("data-vod-player-watch-url-value=\"/api/artists/thecyberpulse/vods/#{stream.id}/watch\"")
      expect(response.body).to include("← Back to Videos")
    end

    it "falls back to a YouTube link when the video id is unrecognizable" do
      stream = create(:hackr_stream, artist: artist, vod_url: "https://example.com/not-youtube")

      get "/thecyberpulse/vidz/#{stream.id}"

      expect(response.body).to include("Unable to load video player.")
      expect(response.body).to include("Watch on YouTube")
    end

    it "renders the error state with 404 for unknown VODs" do
      artist

      get "/thecyberpulse/vidz/999999"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Failed to load video")
      expect(response.body).to include("Back to Videos")
    end

    it "shows an XERAEN recording on the archive, crediting the watch against XERAEN" do
      artist
      stream = create(:hackr_stream, artist: create(:artist, :xeraen), title: "Chaddin Session",
        vod_url: "https://www.youtube.com/embed/dQw4w9WgXcQ")

      get "/thecyberpulse/vidz/#{stream.id}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Chaddin Session")
      expect(response.body).to include('data-vod-player-video-id-value="dQw4w9WgXcQ"')
      expect(response.body).to include("data-vod-player-watch-url-value=\"/api/artists/xeraen/vods/#{stream.id}/watch\"")
    end

    it "redirects the legacy XERAEN VOD path onto the archive" do
      get "/xeraen/vidz/42"

      expect(response).to redirect_to("/thecyberpulse/vidz/42")
    end

    it "404s for a stream outside the archive or without a recording" do
      artist
      elsewhere = create(:hackr_stream, :with_vod, artist: create(:artist))
      unrecorded = create(:hackr_stream, artist: artist, vod_url: nil)

      get "/thecyberpulse/vidz/#{elsewhere.id}"
      expect(response).to have_http_status(:not_found)

      get "/thecyberpulse/vidz/#{unrecorded.id}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
