module GridAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_hackr, :logged_in?, :admin_hackr?
  end

  # Authentication methods

  def current_hackr
    @current_hackr ||= GridHackr.find_by(id: session[:grid_hackr_id]) if session[:grid_hackr_id]
  end

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
