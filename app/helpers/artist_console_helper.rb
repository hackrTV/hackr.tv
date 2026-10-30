# The artist console screens — /xeraen* and /thecyberpulse* on the home
# console family (home_streams.md § Home console): the destination rows
# every screen ends on and the "> " prompt's hint line, both keyed by
# artist slug so the catalog console templates (console_releases /
# console_release / console_track) stay slug-agnostic. Adding an artist to
# the console = a row set here, the slug in
# ArtistCatalogController::CONSOLE_CATALOG_SLUGS, and a .console--<slug>
# brand block in artist_pages.css.
module ArtistConsoleHelper
  # [TAG, href, name, description] per artist. The first row is the
  # artist's home (its tag is the "[<]" label on the catalog screens); the
  # tag doubles as the prompt command (the terminal controller reads
  # a[data-command]). The vault filter is the artist's display name — the
  # vault's track filter is a case-insensitive substring match.
  CONSOLE_DESTINATIONS = {
    "xeraen" => [
      ["XERAEN", "/xeraen", "XERAEN", "The operative record"],
      ["BIO", "/xeraen/bio", "Bio", "The story behind the broadcasts. How a systems architect broke time open and what he lost doing it."],
      ["RELEASES", "/xeraen/releases", "Releases", "Every transmission committed to record. Hardcore fury to OMNIWAVE and everything between."],
      ["VAULT", "/vault?filter=xeraen", "Pulse Vault", "Listen — every XERAEN track in the vault"],
      ["TCP", "/thecyberpulse", "The.CyberPul.se", "Flagship Standard Bearers of the Hackrs of CyberSpace"],
      ["FNET", "/f/net", "Fracture Network", "Back to the network"]
    ],
    "thecyberpulse" => [
      ["TCP", "/thecyberpulse", "The.CyberPul.se", "Transmission origin and broadcast hub"],
      ["BIO", "/thecyberpulse/bio", "Bio", "Who they are. How this started. What it costs them to keep transmitting."],
      ["RELEASES", "/thecyberpulse/releases", "Releases", "Albums, EPs and singles from across the timeline. Every transmission committed to record."],
      ["VIDZ", "/thecyberpulse/vidz", "Vidz", "Visual transmissions — live operations, broadcasts and archived footage"],
      ["VAULT", "/vault?filter=the.cyberpul.se", "Pulse Vault", "Listen — every The.CyberPul.se track in the vault"],
      ["GRID", "/grid", "The Pulse Grid", "Where operators train, plan and execute. You thought you were playing."],
      ["XERAEN", "/xeraen", "XERAEN", "The voice behind the broadcast — his operative record"],
      ["FNET", "/f/net", "Fracture Network", "Back to the network"]
    ]
  }.freeze

  def console_destinations(slug)
    CONSOLE_DESTINATIONS.fetch(slug.to_s, [])
  end

  # "XERAEN" / "TCP" — the catalog screens' "[<]" label.
  def console_home_tag(slug)
    console_destinations(slug).dig(0, 0) || slug.to_s.upcase
  end

  # The prompt's hint: "type a track number (01 02) or type a tag (bio
  # releases …) · enter · ? help". except: the page's own tag, left out as
  # its row is; numbers: the page's numbered rows, if any.
  def console_prompt_hint(slug, except: nil, numbers: [], noun: "a track number")
    tags = console_destinations(slug).map(&:first).reject { |t| t == except }.map(&:downcase)
    parts = []
    parts << safe_join(["type #{noun} ", tag.span("(#{numbers.join(" ")})", class: "console-dim"), " or "]) if numbers.any?
    parts << "type a tag " << tag.span("(#{tags.join(" ")})", class: "console-dim") << " · enter · ? help"
    safe_join(parts)
  end

  # Where a release opens on the console: a single (Release#single? — one
  # released track) is its track's page; anything else the release
  # screen. The ledger rows and the landings' LATEST link go through here.
  def console_release_path(slug, release)
    if release.single?
      "/#{slug}/trackz/#{release.tracks.first.slug}"
    else
      "/#{slug}/releases/#{release.slug}"
    end
  end

  # Hover peek (the peek controller): data attrs for a thumb whose large
  # rendition opens beside it on hover. fallback: a second URL tried when
  # the first 404s (YouTube's maxresdefault is missing for older uploads).
  def peek_attrs(src, fallback: nil)
    {controller: "peek", peek_src_value: src, peek_fallback_value: fallback,
     action: "mouseenter->peek#show mouseleave->peek#hide"}.compact
  end

  # The YouTube renditions for a VOD thumb's peek: maxresdefault first.
  def youtube_peek_attrs(video_id)
    peek_attrs("https://img.youtube.com/vi/#{video_id}/maxresdefault.jpg",
      fallback: "https://img.youtube.com/vi/#{video_id}/hqdefault.jpg")
  end
end
