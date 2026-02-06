# Rack middleware that redirects paths with uppercase letters to their lowercase equivalents.
# Uses 301 (permanent) redirects for SEO-friendly canonical URLs.
class LowercaseRedirect
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"]

    # Skip paths with case-sensitive tokens
    unless skip_path?(path)
      lowercase_path = path.downcase

      if path != lowercase_path
        query_string = env["QUERY_STRING"]
        location = lowercase_path
        location += "?#{query_string}" if query_string && !query_string.empty?

        return [301, {"Location" => location, "Content-Type" => "text/html"}, ["Moved Permanently"]]
      end
    end

    @app.call(env)
  end

  private

  # Asset file extensions that should not be redirected
  ASSET_EXTENSIONS = %w[
    .js .css .map .png .jpg .jpeg .gif .svg .ico .webp .avif
    .woff .woff2 .ttf .eot .otf
    .mp3 .wav .ogg .flac .aac .m4a
    .mp4 .webm .mov
    .json .xml .txt .pdf
  ].freeze

  def skip_path?(path)
    # Skip /shared/ paths (case-sensitive playlist tokens)
    return true if path.start_with?("/shared/")
    # Skip /api/shared_playlists/ paths
    return true if path.start_with?("/api/shared_playlists/")
    # Skip /grid/verify/ paths (case-sensitive registration tokens)
    return true if path.start_with?("/grid/verify/")
    return true if path.start_with?("/api/grid/verify/")
    # Skip asset paths
    return true if path.start_with?("/assets/")
    return true if path.start_with?("/vite-dev/")
    # Skip files with asset extensions (case-insensitive check)
    return true if ASSET_EXTENSIONS.any? { |ext| path.downcase.end_with?(ext) }

    false
  end
end
