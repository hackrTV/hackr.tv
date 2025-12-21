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

  def skip_path?(path)
    # Skip /shared/ paths (case-sensitive playlist tokens)
    return true if path.start_with?("/shared/")
    # Skip /api/shared_playlists/ paths
    return true if path.start_with?("/api/shared_playlists/")

    false
  end
end
