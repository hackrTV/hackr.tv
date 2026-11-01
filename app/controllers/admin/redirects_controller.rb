# /root/redirects — the redirects ledger and the redirect record as
# console screens (2026-10-31; root_console.css). The record screen is
# the edit screen: show redirects there.
class Admin::RedirectsController < Admin::ApplicationController
  before_action :set_redirect, only: [:show, :edit, :update, :destroy]

  def index
    @redirects = Redirect.order(:domain, :path)
  end

  def show
    redirect_to edit_admin_redirect_path(@redirect)
  end

  def new
    @redirect = Redirect.new
  end

  def create
    @redirect = Redirect.new(redirect_params)
    if @redirect.save
      set_flash_success("Redirect created: #{@redirect.path} > #{@redirect.destination_url}")
      redirect_to edit_admin_redirect_path(@redirect)
    else
      flash.now[:error] = "Failed to create redirect: #{@redirect.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @redirect.update(redirect_params)
      set_flash_success("Redirect updated: #{@redirect.path} > #{@redirect.destination_url}")
      redirect_to edit_admin_redirect_path(@redirect)
    else
      flash.now[:error] = "Failed to update redirect: #{@redirect.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    path = @redirect.path
    @redirect.destroy!
    set_flash_success("Redirect '#{path}' deleted.")
    redirect_to admin_redirects_path
  end

  private

  def set_redirect
    @redirect = Redirect.find(params[:id])
  end

  def redirect_params
    params.require(:redirect).permit(:path, :destination_url, :domain)
  end
end
