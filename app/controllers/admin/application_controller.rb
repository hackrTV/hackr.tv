class Admin::ApplicationController < ApplicationController
  include GridAuthentication
  include Admin::DevToolsGate

  layout "admin"

  default_form_builder TuiFormBuilder

  before_action :require_admin

  private

  def set_flash_success(message)
    flash[:success] = message
  end

  def set_flash_error(message)
    flash[:error] = message
  end
end
