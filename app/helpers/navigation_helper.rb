module NavigationHelper
  # Path prefixes served by Hotwire (Turbo-navigable). Everything else is
  # still the React SPA, so nav links get data-turbo=false and cross-stack
  # navigation is a full page load (the SPA mounts on DOMContentLoaded,
  # which never fires on a Turbo visit). Grows as migration phases land.
  HOTWIRE_PATHS = %w[/logs /codex /handbook /schedule /timeline /code].freeze

  def hotwire_path?(path)
    HOTWIRE_PATHS.any? { |prefix| path == prefix || path.start_with?("#{prefix}/") }
  end

  # Nav link that is Turbo-navigable only for migrated paths.
  def nav_link_to(path, css_class: nil, &block)
    options = {}
    options[:class] = css_class if css_class
    options[:data] = {turbo: false} unless hotwire_path?(path)
    link_to(path, **options, &block)
  end

  # Mirrors the SPA's isActive: exact match for "/", prefix match elsewhere.
  def nav_active?(path)
    return request.path == "/" if path == "/"
    request.path == path || request.path.start_with?("#{path}/")
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
