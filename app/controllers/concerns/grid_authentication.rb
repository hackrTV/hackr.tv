module GridAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_hackr, :logged_in?, :admin_hackr?
  end

  # Authentication methods

  def current_hackr
    @current_hackr ||= authenticate_with_token || session_hackr
  end

  def api_token_request?
    request.headers["Authorization"]&.start_with?("Bearer ")
  end

  private

  def authenticate_with_token
    auth_header = request.headers["Authorization"]
    return nil unless auth_header&.start_with?("Bearer ")

    credentials = auth_header.split(" ", 2).last
    return nil if credentials.blank?

    hackr_alias, token = credentials.split(":", 2)
    return nil unless hackr_alias.present? && token.present?

    hackr = GridHackr.authenticate_by_token(hackr_alias, token)
    if hackr.nil?
      token_prefix = (token.length > 8) ? "#{token[0, 8]}..." : token
      Rails.logger.warn("[AUTH] Invalid API token: alias=#{hackr_alias} token_prefix=#{token_prefix} ip=#{request.remote_ip}")
    end
    hackr
  end

  def session_hackr
    GridHackr.find_by(id: session[:grid_hackr_id]) if session[:grid_hackr_id]
  end

  public

  def logged_in?
    current_hackr.present?
  end

  def admin_hackr?
    logged_in? && current_hackr.role == "admin"
  end

  def log_in(hackr)
    session[:grid_hackr_id] = hackr.id
    cookies.encrypted[:grid_hackr_id] = hackr.id # For Action Cable authentication
    @current_hackr = hackr
  end

  def log_out
    session.delete(:grid_hackr_id)
    cookies.delete(:grid_hackr_id)
    @current_hackr = nil
  end

  # Authorization filters

  def require_login
    return if logged_in?

    flash[:error] = "Access denied. Please log in to THE PULSE GRID."
    redirect_to grid_login_path(no_layout: params[:no_layout])
  end

  def require_login_api
    return if logged_in?

    Rails.logger.warn("API auth required: #{request.method} #{request.fullpath}")
    render json: {
      success: false,
      error: "Authentication required. Please log in to THE PULSE GRID.",
      logged_in: false
    }, status: :unauthorized
  end

  def require_feature_api(feature_name)
    return unless logged_in?
    return if current_hackr.has_feature?(feature_name)

    render json: {
      success: false,
      error: "Access to this feature has not been granted yet.",
      feature_locked: true
    }, status: :forbidden
  end

  def require_admin
    return if admin_hackr?

    flash[:error] = "Access denied. Admin privileges required."
    redirect_to grid_path(no_layout: params[:no_layout])
  end

  def require_logout
    return unless logged_in?

    flash[:notice] = "You are already logged into THE PULSE GRID."
    redirect_to grid_path(no_layout: params[:no_layout])
  end
end
