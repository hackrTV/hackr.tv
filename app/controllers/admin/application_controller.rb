class Admin::ApplicationController < ApplicationController
  include GridAuthentication
  include Admin::DevToolsGate

  layout "admin"

  # The /root console's rc_* fields (console-ui-for-all-admin, 2026-10-30);
  # the legacy tui_* family still answers through its superclass.
  default_form_builder ConsoleFormBuilder

  before_action :require_admin

  private

  def set_flash_success(message)
    flash[:success] = message
  end

  def set_flash_error(message)
    flash[:error] = message
  end
end
