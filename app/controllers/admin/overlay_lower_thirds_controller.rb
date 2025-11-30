class Admin::OverlayLowerThirdsController < Admin::ApplicationController
  before_action :set_lower_third, only: [:show, :edit, :update, :destroy]

  def index
    @lower_thirds = OverlayLowerThird.order(:name)
  end

  def show
  end

  def new
    @lower_third = OverlayLowerThird.new
  end

  def create
    @lower_third = OverlayLowerThird.new(lower_third_params)
    if @lower_third.save
      set_flash_success("Lower Third '#{@lower_third.name}' created!")
      redirect_to admin_overlay_lower_thirds_path
    else
      flash.now[:error] = @lower_third.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @lower_third.update(lower_third_params)
      @lower_third.broadcast_update!
      set_flash_success("Lower Third '#{@lower_third.name}' updated!")
      redirect_to admin_overlay_lower_thirds_path
    else
      flash.now[:error] = @lower_third.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @lower_third.name
    @lower_third.destroy
    set_flash_success("Lower Third '#{name}' deleted!")
    redirect_to admin_overlay_lower_thirds_path
  end

  private

  def set_lower_third
    @lower_third = OverlayLowerThird.find_by!(slug: params[:id])
  end

  def lower_third_params
    params.require(:overlay_lower_third).permit(:name, :slug, :primary_text, :secondary_text, :logo_url, :active)
  end
end
