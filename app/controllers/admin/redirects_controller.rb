class Admin::RedirectsController < Admin::ApplicationController
  before_action :set_redirect, only: [:edit, :update, :destroy]

  def index
    @redirects = Redirect.order(:domain, :path)
  end

  def new
    @redirect = Redirect.new
  end

  def create
    @redirect = Redirect.new(redirect_params)
    if @redirect.save
      set_flash_success("Redirect created: #{@redirect.path} → #{@redirect.destination_url}")
      redirect_to admin_redirects_path
    else
      flash.now[:error] = "Failed to create redirect: #{@redirect.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @redirect.update(redirect_params)
      set_flash_success("Redirect updated: #{@redirect.path} → #{@redirect.destination_url}")
      redirect_to admin_redirects_path
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
