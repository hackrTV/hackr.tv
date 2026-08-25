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
  end
end
