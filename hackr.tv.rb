require "haml"
require "sinatra"

set(:public_folder, __dir__ + "/public")

DEFAULT_LAYOUT = :"layouts/application".freeze
LAYOUTS = {xeraen: :"layouts/xeraen"}.freeze

DEFAULT_RESCUE_PATH = "/".freeze
RESCUE_PATHS = {xeraen: "/xeraen"}.freeze

before do
  template_by_url =
    request.path.to_s.split("/").compact.delete_if(&:empty?).join("/").to_sym
  @template = [template_by_url, :index].delete_if(&:empty?).first
  @site_key = request.path.to_s.split("/")[1].to_s.to_sym
end

["/*", "/**/*"].each do |glob|
  get glob do
    haml (LAYOUTS[@site_key] || DEFAULT_LAYOUT) do
      haml @template
    end
  rescue
    redirect (RESCUE_PATHS[@site_key] || DEFAULT_RESCUE_PATH)
  end
end
