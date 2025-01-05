require "haml"
require "sinatra"

FileUtils.rm_rf("public")
FileUtils.mkdir("public")
set(:public_folder, __dir__ + "/public")

# BEGIN Cache-busting
CACHE_BUSTING_TOKEN = DateTime.now.new_offset(0).strftime("%s").freeze

# We'll assume only one level of asset directories for now.
Dir.glob("assets/*").each do |assets_glob|
  Dir.glob(assets_glob).each do |glob|
    dir = glob.split("/")[1]
    FileUtils.mkdir_p "public/#{dir}"
    Dir.glob(glob + "/*").each do |filepath|
      next if File.directory?(filepath)
      filename = filepath.split("/").last
      file_data =
        File
          .read(filepath)
          .gsub("~~~CACHE_BUSTING_TOKEN~~~", CACHE_BUSTING_TOKEN)
      File.write("public/#{dir}/#{CACHE_BUSTING_TOKEN}_#{filename}", file_data)
    end
  end
end
# END Cache-busting

DEFAULT_LAYOUT = :"layouts/application"
LAYOUTS = {xeraen: :"layouts/xeraen"}.freeze

DEFAULT_RESCUE_PATH = "/".freeze
RESCUE_PATHS = {xeraen: "/xeraen"}.freeze

ASHLINN_REDIRECTS = {
  "/" => "https://youtube.com/AshlinnSnow"
}.freeze
XERAEN_REDIRECTS = {
  "/" => "/xeraen",
  "/twitter" => "https://x.com/xeraen",
  "/youtube" => "https://youtube.com/@xeraen"
}.freeze

# This hash will accept full-domain keys as well as @site_key keys.
REDIRECTS = {
  "ashlinn.net" => ASHLINN_REDIRECTS,
  "rockerboy.net" => XERAEN_REDIRECTS,
  "xeraen.com" => XERAEN_REDIRECTS,
  "xeraen.net" => XERAEN_REDIRECTS,
  "xeraen" => XERAEN_REDIRECTS
}

before do
  template_by_url =
    request.path.to_s.split("/").compact.delete_if(&:empty?).join("/")
  @template = [template_by_url.to_sym, :index].delete_if(&:empty?).first
  @site_key = request.path.to_s.split("/")[1].to_s.to_sym
  @redirect_map =
    REDIRECTS[request.host.to_s.downcase] ||
    REDIRECTS[@site_key.to_s.downcase] ||
    {}

  # @context_path turns a symbol like :"xeraen/twitter" into "/twitter"
  @context_path = @template.to_s.gsub(@site_key.to_s, "")

  @redirect_url = @redirect_map[@context_path]
end

["/*", "/**/*"].each do |glob|
  get glob do
    break redirect(@redirect_url) unless @redirect_url.nil?

    haml(LAYOUTS[@site_key] || DEFAULT_LAYOUT) do
      haml @template
    end
  rescue
    redirect(RESCUE_PATHS[@site_key] || DEFAULT_RESCUE_PATH)
  end
end
