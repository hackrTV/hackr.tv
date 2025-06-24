require "erb"
require "sinatra"

set(:public_folder, __dir__ + "/public")
set(
  :host_authorization,
  {
    permitted_hosts: [
      "ashlinn.net",
      "cyberpul.se",
      "hackr.tv",
      "localhost",
      "rockerboy.net",
      "rockerboy.stream",
      "sectorx.hackr",
      "sectorx.media",
      "the.cyberpul.se",
      "what.is.the.cyberpul.se",
      "xeraen.com",
      "xeraen.net",
      "xeraen.hackr"
    ]
  }
)

PRIMARY_DOMAIN =
  if settings.environment == :development
    "localhost:9292"
  else
    "hackr.tv"
  end

CACHE_BUSTING_TOKEN_PATH = "public/cache_busting_token"

if File.file?(CACHE_BUSTING_TOKEN_PATH)
  CACHE_BUSTING_TOKEN = File.read(CACHE_BUSTING_TOKEN_PATH).strip.delete(" ")
else
  p "[[ =========================================== ]]"
  p "[[   CACHE_BUSTING_TOKEN_PATH is not a File!   ]]"
  p "[[ =========================================== ]]"

  CACHE_BUSTING_TOKEN = ""
end

DEFAULT_LAYOUT = :"layouts/default"
LAYOUTS = {
  xeraen: :"layouts/xeraen",
  sector: :"layouts/sector"
}.freeze

DEFAULT_RESCUE_PATH = "/".freeze
RESCUE_PATHS = {xeraen: "/xeraen"}.freeze

###############################################################################
# BEGIN REDIRECTS
###############################################################################
ASHLINN_REDIRECTS = {
  "/" => "https://youtube.com/AshlinnSnow"
}.freeze
XERAEN_REDIRECTS = {
  "/" => "/xeraen",
  "/git" => "https://github.com/xeraen",
  "/github" => "https://github.com/xeraen",
  "/twitter" => "https://x.com/xeraen",
  "/x" => "https://x.com/xeraen",
  "/youtube" => "https://youtube.com/@xeraen"
}.freeze
SECTOR_X_REDIRECTS = {
  "/" => "/sector/x"
}
# This hash will accept full-domain keys as well as @site_key keys.
REDIRECTS = {
  "ashlinn" => ASHLINN_REDIRECTS,
  "ashlinn.net" => ASHLINN_REDIRECTS,
  "rockerboy" => XERAEN_REDIRECTS,
  "rockerboy.net" => XERAEN_REDIRECTS,
  "xeraen" => XERAEN_REDIRECTS,
  "xeraen.com" => XERAEN_REDIRECTS,
  "xeraen.net" => XERAEN_REDIRECTS,
  "xeraen.hackr" => XERAEN_REDIRECTS,
  "xeraen.hackr:9292" => XERAEN_REDIRECTS
}
###############################################################################
# END REDIRECTS
###############################################################################

before do
  template_by_url =
    request
      .path
      .to_s
      .split("/")
      .compact
      .delete_if(&:empty?)
      .join("/")

  @template = [template_by_url.to_sym, :index].delete_if(&:empty?).first
  @site_key = request.path.to_s.split("/")[1].to_s.to_sym
  @redirect_map =
    REDIRECTS[request.host.to_s.downcase] ||
    REDIRECTS[@site_key.to_s.downcase] ||
    {}

  # @context_path turns a symbol like :"xeraen/twitter" into "/twitter"
  @context_path = @template.to_s.gsub(@site_key.to_s, "")

  @redirect_url = @redirect_map[@context_path]
  @protocol = request.secure? ? "https" : "http"
end

["/*", "/**/*"].each do |glob|
  get glob do
    domain = request.server_name.to_s.downcase

    # Make sure that we're always representing hackr.tv as the domain unless
    # we're handling Ashlinn stuff.
    if domain.include?("xeraen") || domain.include?("rockerboy")
      break redirect("#{@protocol}://#{PRIMARY_DOMAIN}/xeraen#{request.path}")
    elsif domain.include?("ashlinn")
      break redirect("https://youtube.com/AshlinnSnow")
    elsif domain.include?("sector")
      break redirect("#{@protocol}://#{PRIMARY_DOMAIN}/sector/x#{request.path}")
    end

    break redirect(@redirect_url) unless @redirect_url.nil?

    erb(LAYOUTS[@site_key] || DEFAULT_LAYOUT) do
      erb @template
    end
  rescue
    redirect(RESCUE_PATHS[@site_key] || DEFAULT_RESCUE_PATH)
  end
end
