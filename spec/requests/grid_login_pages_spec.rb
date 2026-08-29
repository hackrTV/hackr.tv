require "rails_helper"

# Server-rendered login + 2FA interstitial (Hotwire migration Phase 2).
# The JSON login/verify endpoints keep their own specs; these cover the
# HTML routes and their session side-effects.
RSpec.describe "Grid login pages", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  describe "GET /grid/login" do
    it "renders the login form" do
      get "/grid/login"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FRACTURE NETWORK LOGIN")
      expect(response.body).to include("HACKR ALIAS")
      expect(response.body).to include("CONNECT")
    end

    it "redirects logged-in hackrs home" do
      post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}

      get "/grid/login"
      expect(response).to redirect_to("/grid")
    end
  end

  describe "POST /grid/login" do
    it "logs in and redirects to the grid" do
      post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}

      expect(response).to redirect_to("/grid")
      expect(session[:grid_hackr_id]).to eq(hackr.id)
    end

    it "re-renders with the API's error copy on a wrong password" do
      post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "wrong"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include("Invalid hackr alias or password. Access denied.")
      expect(response.body).to include(hackr.hackr_alias) # alias preserved in the form
      expect(session[:grid_hackr_id]).to be_nil
    end

    it "rejects disabled accounts" do
      hackr.update!(login_disabled: true)

      post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("This account has been disabled.")
      expect(session[:grid_hackr_id]).to be_nil
    end

    context "with 2FA enabled" do
      let(:secret) { ROTP::Base32.random }

      before do
        hackr.update!(otp_secret: secret, otp_required_for_login: true)
      end

      it "defers login and redirects to the verify page" do
        post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}

        expect(response).to redirect_to("/grid/login/verify")
        expect(session[:grid_hackr_id]).to be_nil
        expect(session[:pending_2fa_hackr_id]).to eq(hackr.id)
      end
    end
  end

  describe "GET /grid/login/verify" do
    it "redirects to login without a pending 2FA session" do
      get "/grid/login/verify"

      expect(response).to redirect_to("/grid/login")
      expect(flash[:error]).to include("No pending authentication session")
    end
  end

  describe "POST /grid/login/verify" do
    let(:secret) { ROTP::Base32.random }

    before do
      hackr.update!(otp_secret: secret, otp_required_for_login: true)
      post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
    end

    it "completes login with a valid TOTP code" do
      post "/grid/login/verify", params: {totp_code: ROTP::TOTP.new(secret).now}

      expect(response).to redirect_to("/grid")
      expect(session[:grid_hackr_id]).to eq(hackr.id)
      expect(session[:pending_2fa_hackr_id]).to be_nil
    end

    it "completes login with a backup code and consumes it" do
      codes = hackr.generate_backup_codes!

      post "/grid/login/verify", params: {totp_code: codes.first}

      expect(response).to redirect_to("/grid")
      expect(session[:grid_hackr_id]).to eq(hackr.id)
      expect(hackr.reload.otp_backup_code_digests.length).to eq(codes.length - 1)
    end

    it "re-renders the verify form on an invalid code" do
      post "/grid/login/verify", params: {totp_code: "000000"}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include("Invalid code. Access denied.")
      expect(session[:grid_hackr_id]).to be_nil
    end

    it "expires the pending session after 10 minutes" do
      travel 11.minutes do
        post "/grid/login/verify", params: {totp_code: ROTP::TOTP.new(secret).now}

        expect(response).to redirect_to("/grid/login")
        expect(session[:grid_hackr_id]).to be_nil
      end
    end

    it "rejects accounts disabled mid-flow" do
      hackr.update!(login_disabled: true)

      post "/grid/login/verify", params: {totp_code: ROTP::TOTP.new(secret).now}

      expect(response).to redirect_to("/grid/login")
      expect(flash[:error]).to include("This account has been disabled.")
      expect(session[:pending_2fa_hackr_id]).to be_nil
    end
  end
end
