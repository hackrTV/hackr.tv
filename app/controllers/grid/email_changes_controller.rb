# Server-rendered email change (Hotwire migration Phase 2) — ports the
# identity page's CHANGE EMAIL form + GridConfirmEmailChangePage.tsx.
# Mirrors Api::GridController#request_email_change / #confirm_email_change.
#
# Deviation from the SPA: the confirm page shows an explicit button
# instead of auto-confirming on mount — a server-side GET that consumed
# the single-use token would be burned by email-scanner link prefetchers.
class Grid::EmailChangesController < ApplicationController
  layout "hotwire"

  before_action :require_login, only: [:create]

  # POST /grid/identity/email_change — request a change (from identity).
  def create
    new_email = params[:new_email].to_s.downcase.strip

    if (error = request_error(new_email))
      flash[:x_email_error] = error
      flash[:x_email_value] = new_email
    else
      token = GridVerificationToken.create!(
        grid_hackr: current_hackr,
        purpose: "email_change",
        metadata: {new_email: new_email},
        ip_address: request.remote_ip
      )
      GridMailer.email_change_verification(token).deliver_later
      Rails.logger.info("[AUTH] Email change verification sent: hackr_alias=#{current_hackr.hackr_alias} new_email=#{new_email} ip=#{request.remote_ip}")
      flash[:x_email_notice] = "Verification email sent to #{new_email}. Check your inbox to confirm the change."
    end

    redirect_to grid_identity_path
  end

  # GET /grid/confirm_email_change/:token — confirm-button landing page.
  def show
    @token = find_email_change_token
    @error = token_error(@token)
  end

  # POST /grid/confirm_email_change/:token
  def confirm
    @token = find_email_change_token
    if (@error = token_error(@token))
      return render :show, status: :unprocessable_entity
    end

    if GridHackr.exists?(email: @token.new_email)
      @error = "This email address is already in use."
      return render :show, status: :unprocessable_entity
    end

    hackr = @token.grid_hackr
    old_email = hackr.email

    begin
      ActiveRecord::Base.transaction do
        hackr.update!(email: @token.new_email)
        @token.mark_used!
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      @error = "This email address is already in use."
      return render :show, status: :unprocessable_entity
    end

    GridMailer.email_change_notification(hackr, old_email).deliver_later
    Rails.logger.info("[AUTH] Email changed: hackr_alias=#{hackr.hackr_alias} old_email=#{old_email} new_email=#{@token.new_email} ip=#{request.remote_ip}")

    @confirmed = true
    render :show
  end

  private

  def request_error(new_email)
    return "New email address is required." if new_email.blank?
    return "Please enter a valid email address." unless new_email.match?(URI::MailTo::EMAIL_REGEXP)
    return "New email must be different from your current email." if new_email == current_hackr.email
    return "This email address is already in use." if GridHackr.exists?(email: new_email)
    nil
  end

  def find_email_change_token
    token = GridVerificationToken.find_by(token: params[:token])
    (token&.purpose == "email_change") ? token : nil
  end

  # nil for a usable token; the API's exact error copy otherwise.
  def token_error(token)
    return "Invalid verification token." if token.nil?
    return "This verification link has already been used." if token.used?
    return "This verification link has expired." if token.expired?
    nil
  end
end
