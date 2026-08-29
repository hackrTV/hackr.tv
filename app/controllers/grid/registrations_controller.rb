# Server-rendered registration (Hotwire migration Phase 2) — ports
# GridRegisterPage.tsx (email step) and GridVerifyPage.tsx (token check +
# completion form). Mirrors Api::GridController#register / #verify_token /
# #complete_registration, which stay for the SPA until Phase 7.
class Grid::RegistrationsController < ApplicationController
  layout "hotwire"

  before_action :require_logout

  def new
    @sent_email = flash[:x_registration_sent]
  end

  # POST /grid/register — email step. PRG: the "check your inbox" panel
  # renders from a data-carrying flash, so refresh shows the form again.
  def create
    email = params[:email].to_s.downcase.strip

    if email.blank?
      @error = "Email address is required."
      return render :new, status: :unprocessable_entity
    end

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      @error = "Please enter a valid email address."
      return render :new, status: :unprocessable_entity
    end

    if GridHackr.exists?(email: email)
      @error = "This email address is already registered. Try logging in instead."
      return render :new, status: :unprocessable_entity
    end

    token = GridRegistrationToken.create!(email: email, ip_address: request.remote_ip)
    GridMailer.registration_verification(token).deliver_later

    Rails.logger.info("[AUTH] Registration email sent: email=#{email} ip=#{request.remote_ip}")
    flash[:x_registration_sent] = email
    redirect_to grid_register_path
  end

  # GET /grid/verify/:token — the view renders the completion form for a
  # usable token, the failure panel otherwise.
  def verify
    @token = GridRegistrationToken.find_by(token: params[:token])
    @error = token_error(@token)
  end

  # POST /grid/verify/:token — complete registration. Mirrors the API's
  # provisioning sequence exactly (it differs from the login-time
  # establish_grid_session: tutorial always starts, economy is
  # provisioned, no achievement sweep — do not merge them).
  def complete
    @token = GridRegistrationToken.find_by(token: params[:token])
    if (error = token_error(@token))
      @error = error
      return render :verify, status: :unprocessable_entity
    end

    @hackr = GridHackr.new(
      email: @token.email,
      hackr_alias: params[:hackr_alias],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )
    @hackr.enforce_alias_length = true
    @hackr.registration_ip = request.remote_ip

    saved = false
    ActiveRecord::Base.transaction do
      if @hackr.save
        @hackr.ensure_current_room!
        @token.mark_used!
        Grid::TutorialService.new(@hackr).start!
        @hackr.provision_economy!
        log_in(@hackr)
        @hackr.touch_activity!
        saved = true
        Rails.logger.info("[AUTH] Registration completed: hackr_alias=#{@hackr.hackr_alias} email=#{@token.email} ip=#{request.remote_ip}")
      else
        Rails.logger.warn("[AUTH] Registration completion failed: email=#{@token.email} errors=#{@hackr.errors.full_messages.join("; ")} ip=#{request.remote_ip}")
      end
    end

    if saved
      # Publish after the transaction commits so rollback doesn't leave
      # phantom events (same ordering as the API action).
      WorldEventFeed::Publisher.publish(
        event_type: "hackr_registered",
        hackr_alias: @hackr.hackr_alias,
        data: {}
      )
      redirect_to grid_path
    else
      @error = "Registration failed: #{@hackr.errors.full_messages.join(", ")}"
      render :verify, status: :unprocessable_entity
    end
  end

  private

  # nil for a usable token; the API's exact error copy otherwise.
  def token_error(token)
    return "Invalid verification link." if token.nil?
    return "This verification link has already been used." if token.used?
    return "This verification link has expired. Please register again." if token.expired?
    nil
  end
end
