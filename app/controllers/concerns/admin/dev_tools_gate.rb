# frozen_string_literal: true

module Admin::DevToolsGate
  extend ActiveSupport::Concern

  included do
    helper_method :dev_tools_enabled?
  end

  private

  def dev_tools_enabled?
    ENV["ADMIN_DEV_TOOLS"].to_s.downcase == "true"
  end

  def require_dev_tools
    return if dev_tools_enabled?

    set_flash_error("DEV TOOLS DISABLED. Set ADMIN_DEV_TOOLS=true to enable.")
    redirect_to admin_root_path
  end
end
