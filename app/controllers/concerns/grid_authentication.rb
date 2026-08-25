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
      return nil
    end

    if hackr.login_disabled? && !hackr.service_account?
      Rails.logger.warn("[AUTH] API token rejected (disabled): alias=#{hackr_alias} ip=#{request.remote_ip}")
      return nil
    end

    hackr
  end

  def session_hackr
    return nil unless session[:grid_hackr_id]
    hackr = GridHackr.find_by(id: session[:grid_hackr_id])
    if hackr&.login_disabled?
      log_out
      return nil
    end
    hackr
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
    session.delete(:pending_2fa_hackr_id)
    cookies.delete(:grid_hackr_id)
    @current_hackr = nil
  end

  # Complete a successful authentication: room safety, first-login tutorial
  # bootstrap, session + Cable cookie, activity touch, achievement sweep.
  # Shared by the JSON login/TOTP-verify actions and the Hotwire session
  # controller so the side-effect chain can't drift between stacks. The
  # 2FA-completing path passes tutorial_check: false — it never ran the
  # tutorial bootstrap (pre-existing asymmetry, preserved).
  def establish_grid_session(hackr, tutorial_check: true)
    hackr.ensure_current_room!

    # Start tutorial for hackrs who haven't seen it (e.g., seeded accounts)
    if tutorial_check && hackr.stat("tutorial_active").nil? && hackr.stat("tutorial_completed").nil?
      tutorial = Grid::TutorialService.new(hackr)
      tutorial.start!
      # Move to Bootloader hub (start! doesn't move — only sets state)
      hub = tutorial.tutorial_hub_room
      hackr.update!(current_room: hub) if hub
      # Remove den chip if provisioned before tutorial was set up.
      # Skip if hackr already has a den (chip was already used).
      unless hackr.den.present?
        hackr.grid_items.joins(:grid_item_definition)
          .where(grid_item_definitions: {slug: "den-access-chip"}).destroy_all
      end
    end

    log_in(hackr)
    hackr.touch_activity!
    Grid::AchievementSweepJob.perform_later(hackr.id)
  end

  PENDING_2FA_EXPIRY = 10.minutes

  def pending_2fa_hackr
    return nil unless session[:pending_2fa_hackr_id]
    if session[:pending_2fa_at] && Time.current.to_i - session[:pending_2fa_at].to_i > PENDING_2FA_EXPIRY.to_i
      clear_pending_2fa
      return nil
    end
    GridHackr.find_by(id: session[:pending_2fa_hackr_id])
  end

  def clear_pending_2fa
    session.delete(:pending_2fa_hackr_id)
    session.delete(:pending_2fa_at)
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

  def require_admin_api
    return if logged_in? && current_hackr.admin?

    render json: {
      success: false,
      error: "Admin access required."
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
