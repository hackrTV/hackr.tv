class Api::TotpController < ApplicationController
  include GridAuthentication
  include GridSerialization

  before_action :require_login_api, only: %i[status setup enable disable regenerate_backup_codes]
  before_action :require_admin_api, only: [:admin_reset]

  # GET /api/totp/status
  def status
    service = Grid::TotpService.new(current_hackr)
    render json: service.status
  end

  # POST /api/totp/setup
  # Generates a new OTP secret + QR code. Does NOT persist or enable 2FA.
  def setup
    service = Grid::TotpService.new(current_hackr)
    data = service.generate_setup_data

    Rails.logger.info("[2FA] TOTP setup initiated: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
    render json: {
      success: true,
      secret: data[:secret],
      qr_svg: data[:qr_svg]
    }
  rescue Grid::TotpService::AlreadyEnabled => e
    render json: {success: false, error: e.message}, status: :unprocessable_entity
  end

  # POST /api/totp/enable
  # Verifies a TOTP code against the staged secret, enables 2FA, returns backup codes.
  def enable
    service = Grid::TotpService.new(current_hackr)
    backup_codes = service.enable!(
      password: params[:password],
      otp_secret: params[:otp_secret],
      totp_code: params[:code]
    )

    Rails.logger.info("[2FA] TOTP enabled: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
    render json: {
      success: true,
      message: "Two-factor authentication enabled.",
      backup_codes: backup_codes
    }
  rescue Grid::TotpService::InvalidPassword => e
    render json: {success: false, error: e.message}, status: :unauthorized
  rescue Grid::TotpService::InvalidCode, Grid::TotpService::AlreadyEnabled => e
    render json: {success: false, error: e.message}, status: :unprocessable_entity
  end

  # POST /api/totp/verify
  # Accepts a TOTP or backup code for pending-2FA session. Completes login.
  def verify
    hackr = pending_2fa_hackr
    unless hackr
      return render json: {success: false, error: "No pending authentication session."}, status: :unauthorized
    end

    if hackr.login_disabled?
      clear_pending_2fa
      return render json: {success: false, error: "This account has been disabled."}, status: :forbidden
    end

    service = Grid::TotpService.new(hackr)
    method = service.verify!(params[:code])

    clear_pending_2fa

    hackr.ensure_current_room!
    log_in(hackr)
    hackr.touch_activity!
    Grid::AchievementSweepJob.perform_later(hackr.id)

    Rails.logger.info("[2FA] Login completed (#{method}): hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
    render json: {
      success: true,
      message: "Welcome back to THE PULSE GRID, #{hackr.hackr_alias}.",
      hackr: auth_hackr_json(hackr)
    }
  rescue Grid::TotpService::InvalidCode
    Rails.logger.warn("[2FA] TOTP verify failed: ip=#{request.remote_ip}")
    render json: {success: false, error: "Invalid code. Access denied."}, status: :unauthorized
  end

  # DELETE /api/totp/disable
  # Requires password + valid TOTP code.
  def disable
    service = Grid::TotpService.new(current_hackr)
    service.disable!(password: params[:password], totp_code: params[:code])

    Rails.logger.info("[2FA] TOTP disabled: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
    render json: {success: true, message: "Two-factor authentication disabled."}
  rescue Grid::TotpService::InvalidPassword => e
    render json: {success: false, error: e.message}, status: :unauthorized
  rescue Grid::TotpService::InvalidCode, Grid::TotpService::NotEnabled => e
    render json: {success: false, error: e.message}, status: :unprocessable_entity
  end

  # POST /api/totp/regenerate_backup_codes
  # Requires password + valid TOTP code. Flushes old codes.
  def regenerate_backup_codes
    service = Grid::TotpService.new(current_hackr)
    backup_codes = service.regenerate_backup_codes!(password: params[:password], totp_code: params[:code])

    Rails.logger.info("[2FA] Backup codes regenerated: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
    render json: {
      success: true,
      message: "Backup codes regenerated. Old codes are now invalid.",
      backup_codes: backup_codes
    }
  rescue Grid::TotpService::InvalidPassword => e
    render json: {success: false, error: e.message}, status: :unauthorized
  rescue Grid::TotpService::InvalidCode, Grid::TotpService::NotEnabled => e
    render json: {success: false, error: e.message}, status: :unprocessable_entity
  end

  # POST /api/totp/admin_reset
  # Admin-only: clears 2FA for a target hackr.
  def admin_reset
    target = GridHackr.find_by(hackr_alias: params[:hackr_alias])
    unless target
      return render json: {success: false, error: "Hackr not found."}, status: :not_found
    end

    service = Grid::TotpService.new(target)
    service.disable_admin!(acting_admin: current_hackr)

    render json: {success: true, message: "2FA cleared for #{target.hackr_alias}."}
  rescue Grid::TotpService::NotEnabled => e
    render json: {success: false, error: e.message}, status: :unprocessable_entity
  end
end
