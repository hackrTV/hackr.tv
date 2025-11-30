class Admin::OverlaysController < Admin::ApplicationController
  # GET /root/overlays
  def index
    @scenes = OverlayScene.ordered
    @elements = OverlayElement.order(:element_type, :name)
    @lower_thirds = OverlayLowerThird.order(:name)
    @tickers = OverlayTicker.all
    @now_playing = OverlayNowPlaying.current
    @tracks = Track.includes(:artist).order("artists.name, tracks.title")
    @pending_alerts = OverlayAlert.pending.count
  end

  # PATCH /root/overlays/ticker/:ticker_slug
  def update_ticker
    @ticker = OverlayTicker.find_by!(slug: params[:ticker_slug])
    if @ticker.update(ticker_params)
      @ticker.broadcast_update!
      set_flash_success("Ticker '#{@ticker.name}' updated!")
    else
      set_flash_error(@ticker.errors.full_messages.join(", "))
    end
    redirect_to admin_overlays_path
  end

  # POST /root/overlays/alert
  def send_alert
    OverlayAlert.queue!(
      type: params[:alert_type] || "custom",
      title: params[:alert_title],
      message: params[:alert_message],
      expires_in: 10.seconds
    )
    set_flash_success("Alert sent!")
    redirect_to admin_overlays_path
  end

  private

  def ticker_params
    params.require(:overlay_ticker).permit(:content, :speed, :direction, :active)
  end
end
