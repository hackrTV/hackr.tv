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
end
