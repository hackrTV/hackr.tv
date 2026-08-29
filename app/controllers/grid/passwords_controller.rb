# Server-rendered password flows (Hotwire migration Phase 2) — ports
# ForgotPasswordPage.tsx + ResetPasswordPage.tsx and the identity page's
# "RESET CREDENTIALS" action. Mirrors Api::GridController#forgot_password /
# #reset_password / #request_password_reset.
class Grid::PasswordsController < ApplicationController
  before_action :require_login, only: [:request_for_current]

  # GET /grid/forgot_password
  def forgot
    @sent_email = flash[:x_reset_sent]
  end

  # POST /grid/forgot_password — always "succeeds" to prevent email
  # enumeration, exactly like the API.
  def request_reset
    email = params[:email].to_s.downcase.strip
    hackr = GridHackr.find_by(email: email)

    if hackr
      token = GridVerificationToken.create!(
        grid_hackr: hackr,
        purpose: "password_reset",
        ip_address: request.remote_ip
      )
      GridMailer.password_reset(token).deliver_later
      Rails.logger.info("[AUTH] Forgot password email sent: email=#{email} ip=#{request.remote_ip}")
    else
      Rails.logger.info("[AUTH] Forgot password attempt for unknown email: ip=#{request.remote_ip}")
    end

    flash[:x_reset_sent] = email
    redirect_to grid_forgot_password_path
  end

  # GET /grid/reset_password/:token — validates the token up front
  # (deviation from the SPA, which always showed the form and only failed
  # on submit; failing early beats a doomed form).
  def edit
    @token = find_reset_token
    @token_error = reset_token_error(@token)
  end

  # POST /grid/reset_password/:token
  def update
    @token = find_reset_token
    if (@token_error = reset_token_error(@token))
      return render :edit, status: :unprocessable_entity
    end

    hackr = @token.grid_hackr
    hackr.password = params[:password]
    hackr.password_confirmation = params[:password_confirmation]

    saved = false
    ActiveRecord::Base.transaction do
      if hackr.save
        @token.mark_used!
        saved = true
        Rails.logger.info("[AUTH] Password reset completed: hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
      end
    end

    if saved
      # The SPA showed an in-page success + "RETURN TO GRID"; the reset
      # never logs you in, so landing on the login page is the honest next
      # step (deviation, noted in the phase doc).
      redirect_to grid_login_path, flash: {success: "Password updated successfully. Log in with your new credentials."}
    else
      @error = "Password update failed: #{hackr.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  # POST /grid/identity/password_reset — logged-in "RESET CREDENTIALS"
  # button on the identity page.
  def request_for_current
    if current_hackr.email.blank?
      flash[:x_password_error] = "No email address on file. Set an email first to enable password reset."
    else
      token = GridVerificationToken.create!(
        grid_hackr: current_hackr,
        purpose: "password_reset",
        ip_address: request.remote_ip
      )
      GridMailer.password_reset(token).deliver_later
      Rails.logger.info("[AUTH] Password reset email sent: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
      flash[:x_password_notice] = "Password reset email sent. Check your inbox."
    end
    redirect_to grid_identity_path
  end

  private

  def find_reset_token
    token = GridVerificationToken.find_by(token: params[:token])
    (token&.purpose == "password_reset") ? token : nil
  end

  # nil for a usable token; the API's exact error copy otherwise.
  def reset_token_error(token)
    return "Invalid reset token." if token.nil?
    return "This reset link has already been used." if token.used?
    return "This reset link has expired." if token.expired?
    nil
  end
end
