# Server-rendered login + 2FA interstitial (Hotwire migration Phase 2) —
# ports GridLoginPage.tsx. The JSON auth endpoints (Api::GridController /
# Api::TotpController) stay for the remaining SPA pages until Phase 7;
# this controller mirrors their logic exactly via establish_grid_session.
#
# The login + verify forms are data-turbo=false: success redirects into
# the SPA-served /grid, which must be a full page load (the SPA mounts on
# DOMContentLoaded, which never fires on a Turbo visit).
class Grid::SessionsController < ApplicationController
  layout "hotwire"

  before_action :require_logout, only: [:new]

  def new
  end

  def create
    hackr = GridHackr.find_by(hackr_alias: params[:hackr_alias])

    if hackr&.authenticate(params[:password])
      if hackr.login_disabled?
        Rails.logger.warn("[AUTH] Login blocked (disabled): hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
        @error = "This account has been disabled."
        return render :new, status: :forbidden
      end

      # 2FA gate: if TOTP enabled, defer login until code is verified
      if hackr.otp_required_for_login?
        session[:pending_2fa_hackr_id] = hackr.id
        session[:pending_2fa_at] = Time.current.to_i
        Rails.logger.info("[AUTH] 2FA required: hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
        return redirect_to grid_login_verify_path
      end

      establish_grid_session(hackr)
      Rails.logger.info("[AUTH] Login success: hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
      redirect_to grid_path
    else
      attempted_alias = params[:hackr_alias].to_s.truncate(50)
      reason = hackr ? "invalid_password" : "unknown_alias"
      Rails.logger.warn("[AUTH] Login failed: attempted_alias=#{attempted_alias} reason=#{reason} ip=#{request.remote_ip}")
      @error = "Invalid hackr alias or password. Access denied."
      render :new, status: :unauthorized
    end
  end

  # GET /grid/login/verify — 2FA interstitial. The SPA swapped the login
  # form in place; the server flow gets a dedicated page bound to the
  # pending-2FA session (10-minute expiry enforced by pending_2fa_hackr).
  def totp
    return if pending_2fa_hackr

    redirect_to grid_login_path, flash: {error: "No pending authentication session. Log in again."}
  end

  def verify_totp
    hackr = pending_2fa_hackr
    unless hackr
      return redirect_to grid_login_path, flash: {error: "No pending authentication session. Log in again."}
    end

    if hackr.login_disabled?
      clear_pending_2fa
      return redirect_to grid_login_path, flash: {error: "This account has been disabled."}
    end

    service = Grid::TotpService.new(hackr)
    method = service.verify!(params[:totp_code])

    clear_pending_2fa
    establish_grid_session(hackr, tutorial_check: false)

    Rails.logger.info("[2FA] Login completed (#{method}): hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
    redirect_to grid_path
  rescue Grid::TotpService::InvalidCode
    Rails.logger.warn("[2FA] TOTP verify failed: ip=#{request.remote_ip}")
    @error = "Invalid code. Access denied."
    render :totp, status: :unauthorized
  end
end
