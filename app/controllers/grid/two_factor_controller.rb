# Server-rendered TOTP management (Hotwire migration Phase 2) — ports
# TwoFactorPage.tsx (its 553 LOC collapse into Grid::TotpService calls +
# three views). Mirrors Api::TotpController; the React page's client-side
# phase machine becomes: show (enabled/disabled + ?mode= confirmation
# forms), setup (GET, idempotent — nothing persists until enable), and a
# render-once backup_codes view.
#
# The staged secret travels through the enable form as a hidden field,
# exactly like the SPA held it in component state.
class Grid::TwoFactorController < ApplicationController
  before_action :require_login

  # GET /grid/identity/two-factor (+ ?mode=disable / ?mode=regenerate)
  def show
    load_status
    @mode = params[:mode] if @status[:enabled] && %w[disable regenerate].include?(params[:mode])
  end

  # GET /grid/identity/two-factor/setup — fresh secret + QR.
  def setup
    data = Grid::TotpService.new(current_hackr).generate_setup_data
    @secret = data[:secret]
    @qr_svg = data[:qr_svg]
    Rails.logger.info("[2FA] TOTP setup initiated: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
  rescue Grid::TotpService::AlreadyEnabled
    redirect_to grid_two_factor_path
  end

  # POST /grid/identity/two-factor/enable
  def enable
    service = Grid::TotpService.new(current_hackr)
    @backup_codes = service.enable!(
      password: params[:password],
      otp_secret: params[:otp_secret],
      totp_code: params[:code]
    )
    Rails.logger.info("[2FA] TOTP enabled: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
    render :backup_codes
  rescue Grid::TotpService::AlreadyEnabled
    redirect_to grid_two_factor_path
  rescue Grid::TotpService::InvalidPassword, Grid::TotpService::InvalidCode, ROTP::Base32::Base32Error => e
    # Re-render the setup form for the already-staged secret. Only a
    # well-formed Base32 secret is accepted back from the hidden field —
    # anything else means a mangled form; start setup over.
    @secret = params[:otp_secret].to_s[/\A[A-Z2-7]{16,64}\z/]
    return redirect_to grid_two_factor_setup_path unless @secret

    @error = e.is_a?(Grid::TotpService::Error) ? e.message : "Invalid TOTP code. Try again."
    @qr_svg = Grid::TotpService.new(current_hackr).generate_setup_data(secret: @secret)[:qr_svg]
    render :setup, status: :unprocessable_entity
  end

  # DELETE /grid/identity/two-factor
  def destroy
    Grid::TotpService.new(current_hackr).disable!(password: params[:password], totp_code: params[:code])
    Rails.logger.info("[2FA] TOTP disabled: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
    redirect_to grid_two_factor_path, flash: {x_tf_notice: "Two-factor authentication disabled."}
  rescue Grid::TotpService::NotEnabled
    redirect_to grid_two_factor_path
  rescue Grid::TotpService::InvalidPassword, Grid::TotpService::InvalidCode => e
    @error = e.message
    load_status
    @mode = "disable"
    render :show, status: :unprocessable_entity
  end

  # POST /grid/identity/two-factor/backup_codes — regenerate.
  def backup_codes
    @backup_codes = Grid::TotpService.new(current_hackr)
      .regenerate_backup_codes!(password: params[:password], totp_code: params[:code])
    Rails.logger.info("[2FA] Backup codes regenerated: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
    render :backup_codes
  rescue Grid::TotpService::NotEnabled
    redirect_to grid_two_factor_path
  rescue Grid::TotpService::InvalidPassword, Grid::TotpService::InvalidCode => e
    @error = e.message
    load_status
    @mode = "regenerate"
    render :show, status: :unprocessable_entity
  end

  private

  def load_status
    @status = Grid::TotpService.new(current_hackr).status
  end
end
