class Admin::OverlayAlertsController < Admin::ApplicationController
  def index
    @alerts = OverlayAlert.recent
    @alerts = @alerts.by_type(params[:alert_type]) if params[:alert_type].present?
    @alerts = @alerts.limit(100)
  end

  def show
    @alert = OverlayAlert.find(params[:id])
  end

  def new
    @alert = OverlayAlert.new(alert_type: "custom")
  end

  def create
    ap = alert_params
    alert = OverlayAlert.queue!(
      type: ap[:alert_type] || "custom",
      title: ap[:title],
      message: ap[:message],
      data: parse_alert_data(ap[:data_json]),
      expires_in: 10.seconds
    )
    set_flash_success("Alert '#{alert.title || alert.alert_type}' sent and broadcast.")
    redirect_to admin_overlay_alerts_path
  rescue => e
    set_flash_error("Failed to send alert: #{e.message}")
    redirect_to new_admin_overlay_alert_path
  end

  def destroy
    alert = OverlayAlert.find(params[:id])
    alert.destroy!
    set_flash_success("Alert deleted.")
    redirect_to admin_overlay_alerts_path
  end

  private

  def alert_params
    params.require(:overlay_alert).permit(:alert_type, :title, :message, :data_json)
  end

  def parse_alert_data(raw)
    return {} if raw.blank?
    JSON.parse(raw)
  rescue JSON::ParserError
    flash[:warning] = "Alert data JSON was invalid and was ignored."
    {}
  end
end
