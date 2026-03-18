class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include RequestAnalysis
  include GridAuthentication

  protect_from_forgery with: :exception, unless: :api_token_request?

  before_action :check_for_redirect
  before_action :check_for_domain_redirect

  helper_method :domain_stylesheet

  # PaperTrail: track which hackr made changes
  def user_for_paper_trail
    current_hackr&.id
  end

  private

  def domain_stylesheet
    return "grid" if request.path.start_with?("/grid")
    return "fm" if request.path.start_with?("/fm")
    return "xeraen" if request.path.start_with?("/xeraen")
    return "sector" if request.path.start_with?("/sector")
    "default"
  end

  def check_for_redirect
    redirect_record = Redirect.find_for(request.host, request.path)
    redirect_to redirect_record.destination_url, allow_other_host: true if redirect_record
  end

  def check_for_domain_redirect
    return if performed?

    domain = request.host.downcase

    # Determine if running in development or production
    primary_domain = Rails.env.production? ? "hackr.tv" : "localhost:3000"
    protocol = request.ssl? ? "https" : "http"

    # Redirect xeraen/rockerboy domains to hackr.tv/xeraen
    if domain.include?("xeraen") || domain.include?("rockerboy")
      path = request.fullpath.sub(%r{^/xeraen}, "")
      redirect_to "#{protocol}://#{primary_domain}/xeraen#{path}", allow_other_host: true
    # Redirect ashlinn to YouTube
    elsif domain.include?("ashlinn")
      redirect_to "https://youtube.com/AshlinnSnow", allow_other_host: true
    # Redirect sector domains to hackr.tv/sector/x
    elsif domain.include?("sector")
      path = request.fullpath.sub(%r{^/sector/x}, "")
      redirect_to "#{protocol}://#{primary_domain}/sector/x#{path}", allow_other_host: true
    # Redirect cyberpul.se domains to hackr.tv/thecyberpulse
    elsif domain.include?("cyberpul")
      path = request.fullpath.sub(%r{^/thecyberpulse}, "")
      redirect_to "#{protocol}://#{primary_domain}/thecyberpulse#{path}", allow_other_host: true
    # Redirect hackr.fm to hackr.tv/fm
    elsif domain.include?("hackr.fm")
      path = request.fullpath.sub(%r{^/fm}, "")
      redirect_to "#{protocol}://#{primary_domain}/fm#{path}", allow_other_host: true
    end
  end
end
