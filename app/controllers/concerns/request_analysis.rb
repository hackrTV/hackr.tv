module RequestAnalysis
  extend ActiveSupport::Concern

  included do
    before_action :analyze_request
    helper_method :mobile?, :ashlinn?, :hackr_tv?, :sector_x?, :xeraen?
  end

  private

  def analyze_request
    @browser = Browser.new(request.user_agent, accept_language: request.headers["HTTP_ACCEPT_LANGUAGE"])
    @domain = request.host.downcase
  end

  def mobile?
    @browser.device.mobile?
  end

  def ashlinn?
    @domain.include?("ashlinn")
  end

  def hackr_tv?
    !ashlinn? && !sector_x? && !xeraen?
  end

  def sector_x?
    @domain.include?("sector") || request.path.include?("/sector")
  end

  def xeraen?
    @domain.include?("xeraen") || @domain.include?("rockerboy") || request.path.include?("/xeraen")
  end
end
