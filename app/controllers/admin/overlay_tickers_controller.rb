class Admin::OverlayTickersController < Admin::ApplicationController
  include Admin::Versionable

  versionable OverlayTicker, find_by: :slug

  before_action :set_ticker, only: %i[show edit update destroy]

  def index
    @tickers = OverlayTicker.ordered
  end

  def show
  end

  def new
    @ticker = OverlayTicker.new(content_type: "static", direction: "left", speed: 50)
  end

  def create
    @ticker = OverlayTicker.new(ticker_params)
    if @ticker.save
      set_flash_success("Ticker '#{@ticker.name}' created.")
      redirect_to admin_overlay_tickers_path
    else
      flash.now[:error] = @ticker.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ticker.update(ticker_params)
      @ticker.broadcast_update!
      set_flash_success("Ticker '#{@ticker.name}' updated and broadcast.")
      redirect_to admin_overlay_tickers_path
    else
      flash.now[:error] = @ticker.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @ticker.name
    @ticker.destroy!
    set_flash_success("Ticker '#{name}' deleted.")
    redirect_to admin_overlay_tickers_path
  end

  private

  def set_ticker
    @ticker = OverlayTicker.find_by!(slug: params[:id])
  end

  def ticker_params
    params.require(:overlay_ticker).permit(:name, :slug, :content, :content_type, :feed_source, :direction, :speed, :active)
  end
end
