module NavigationHelper
  # Nav link helper. The migration-era hotwire_path? gate (data-turbo=false
  # for SPA paths) is gone — every path is Turbo-navigable now.
  def nav_link_to(path, css_class: nil, &block)
    options = {}
    options[:class] = css_class if css_class
    link_to(path, **options, &block)
  end

  # Mirrors the SPA's isActive: exact match for "/", prefix match elsewhere.
  def nav_active?(path)
    return request.path == "/" if path == "/"
    request.path == path || request.path.start_with?("#{path}/")
  end

  # Every artist slug except the two with their own nav entries. On these
  # namespaces the hackr.fm item lights up (header + footer).
  BAND_NAV_SLUGS = (ArtistCatalogHelper::ARTIST_THEME_SLUGS - %w[thecyberpulse xeraen]).freeze

  def band_namespace_active?
    BAND_NAV_SLUGS.any? { |slug| nav_active?("/#{slug}") }
  end

  def world_feed_visible?
    WorldEventSetting.visible?
  end

  def prerelease_mode
    APP_SETTINGS[:prerelease_mode]
  end

  def prerelease_banner_text
    APP_SETTINGS[:prerelease_banner_text]
  end
end
