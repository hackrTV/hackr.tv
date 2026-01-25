# Read-only controller - Redirects are managed via YAML files
# Edit data/system/redirects.yml and run: rails data:redirects
class Admin::RedirectsController < Admin::ApplicationController
  def index
    @redirects = Redirect.order(:domain, :path)
  end
end
