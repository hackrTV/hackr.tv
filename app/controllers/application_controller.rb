class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include RequestAnalysis

  before_action :check_for_redirect
  before_action :check_for_domain_redirect

  layout :current_layout

  private

  def check_for_redirect
    redirect_record = Redirect.find_for(request.host, request.path)
    redirect_to redirect_record.destination_url, allow_other_host: true if redirect_record
  end

  def check_for_domain_redirect
    domain = request.host.downcase

    # Determine if running in development or production
    primary_domain = Rails.env.production? ? "hackr.tv" : "localhost:3000"
    protocol = request.ssl? ? "https" : "http"

    # Redirect xeraen/rockerboy domains to hackr.tv/xeraen
    if domain.include?("xeraen") || domain.include?("rockerboy")
      redirect_to "#{protocol}://#{primary_domain}/xeraen#{request.fullpath}", allow_other_host: true
    # Redirect ashlinn to YouTube
    elsif domain.include?("ashlinn")
      redirect_to "https://youtube.com/AshlinnSnow", allow_other_host: true
    # Redirect sector domains to hackr.tv/sector/x
    elsif domain.include?("sector")
      redirect_to "#{protocol}://#{primary_domain}/sector/x#{request.fullpath}", allow_other_host: true
    end
  end
end
