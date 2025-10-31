module RequestAnalysis
  extend ActiveSupport::Concern

  included do
    before_action :analyze_request
    helper_method :mobile?, :ashlinn?, :hackr_tv?, :sector_x?, :xeraen?, :current_layout
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

  def current_layout
    layout_name = if hackr_tv?
      "default"
    elsif xeraen?
      "xeraen"
    elsif sector_x?
      "sector"
    elsif ashlinn?
      "default"
    end

    layout_name += "_mobile" if mobile? && layout_name
    layout_name
  end
end
