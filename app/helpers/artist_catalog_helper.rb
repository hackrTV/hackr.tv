# View helpers for the Hotwire artist catalog pages (Phase 4).
module ArtistCatalogHelper
  # Slugs with a bespoke scheme in utils/artistColors.ts. Everything else
  # falls back to the defaults on .ac-theme (purple — same as xeraen).
  ARTIST_THEME_SLUGS = %w[
    xeraen thecyberpulse system-rot wavelength-zero voiceprint
    temporal-blue-drift heartbreak-havoc apex-overdrive cipher-protocol
    neon-hearts injection-vector blitzbeam ethereality offline
    the-pulse-grid
  ].freeze

  # Artists whose scheme has a gradient + cycling accentColors.
  PRISMATIC_SLUGS = %w[wavelength-zero].freeze
  PRISMATIC_ACCENT_COUNT = 5

  STREAMING_PLATFORM_ORDER = %w[bandcamp youtube spotify apple_music soundcloud].freeze

  # extractVideoId (VodzPage/VodzShowPage): four URL shapes.
  YOUTUBE_ID_PATTERNS = [
    %r{youtube\.com/embed/([a-zA-Z0-9_-]{11})},
    %r{youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})},
    %r{youtu\.be/([a-zA-Z0-9_-]{11})},
    %r{youtube\.com/live/([a-zA-Z0-9_-]{11})}
  ].freeze

  # ReleaseDetailPage's cycling placeholder names for encrypted tracklists.
  REDACTED_TRACK_NAMES = [
    "[SIGNAL ENCRYPTED]", "[DECRYPTING...]", "[LOCKED]",
    "[FREQUENCY MASKED]", "[INTERCEPTED]", "[AWAITING CLEARANCE]"
  ].freeze

  def artist_theme_class(slug)
    ARTIST_THEME_SLUGS.include?(slug.to_s) ? "ac-theme--#{slug}" : nil
  end

  # Prismatic schemes cycle card/section/row accents by index; solid
  # schemes always use the primary color, so no class is needed (the
  # --ac-accent var defaults to --ac-primary).
  def accent_class(slug, index)
    return nil unless PRISMATIC_SLUGS.include?(slug.to_s)
    "ac-accent-#{index % PRISMATIC_ACCENT_COUNT}"
  end

  # Port of the React comparator: known platforms first in a fixed order,
  # unknown platforms keep insertion order after them.
  def sorted_streaming_links(links)
    links.to_a.each_with_index.sort_by { |(platform, _url), position|
      index = STREAMING_PLATFORM_ORDER.index(platform.to_s.downcase)
      index ? [0, index, position] : [1, position, 0]
    }.map(&:first)
  end

  # Port of titleize(): "youtube" → "YouTube", "apple_music" → "Apple Music".
  def streaming_platform_name(platform)
    return "YouTube" if platform.to_s.downcase == "youtube"
    platform.to_s.tr("_", " ").gsub(/\b\w/) { |char| char.upcase }
  end

  def youtube_video_id(url)
    return nil if url.blank?
    YOUTUBE_ID_PATTERNS.each do |pattern|
      match = url.match(pattern)
      return match[1] if match
    end
    nil
  end

  # TrackDetailPage's vidz thumbnails only matched /embed/ URLs.
  def youtube_embed_id(url)
    url.to_s[%r{embed/([a-zA-Z0-9_-]{11})}, 1]
  end

  def redacted_track_name(index)
    REDACTED_TRACK_NAMES[index % REDACTED_TRACK_NAMES.length]
  end

  # Disc length (ported from Api::ReleasesController): track durations
  # ("M:SS" or "H:MM:SS") summed and rendered M:SS. The release action's
  # @disc_length and the catalog console's index rows both go through
  # here.
  def duration_seconds(duration_str)
    return 0 if duration_str.blank?
    parts = duration_str.split(":").map(&:to_i)
    case parts.length
    when 2 then parts[0] * 60 + parts[1]
    when 3 then parts[0] * 3600 + parts[1] * 60 + parts[2]
    else 0
    end
  end

  def format_seconds(total_seconds)
    "#{total_seconds / 60}:#{(total_seconds % 60).to_s.rjust(2, "0")}"
  end

  # M:SS for a release with timed tracks, nil otherwise.
  def release_length(release)
    seconds = release.tracks.sum { |t| duration_seconds(t.duration) }
    seconds.positive? ? format_seconds(seconds) : nil
  end

  # The catalog console's [TAG] for a streaming platform row.
  STREAMING_TAGS = {
    "bandcamp" => "BC", "youtube" => "YT", "spotify" => "SP",
    "apple_music" => "AM", "soundcloud" => "SC"
  }.freeze

  def streaming_tag(platform)
    STREAMING_TAGS[platform.to_s.downcase] || platform.to_s[0, 2].upcase
  end

  # "open.spotify.com" for a frequency row's description.
  def link_host(url)
    URI.parse(url.to_s).host.to_s.delete_prefix("www.")
  rescue URI::InvalidURIError
    ""
  end
end
