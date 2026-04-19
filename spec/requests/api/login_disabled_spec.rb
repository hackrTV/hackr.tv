require "rails_helper"

RSpec.describe "Login disabled accounts", type: :request do
  let(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  describe "POST /api/grid/login" do
    it "blocks login for disabled accounts" do
      hackr.update!(login_disabled: true)

      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to include("disabled")
    end

    it "allows login for enabled accounts" do
      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["success"]).to be true
    end
  end

  describe "session rehydration" do
    it "logs out disabled hackr on next request" do
      # Log in normally
      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}, as: :json
      expect(response.parsed_body["success"]).to be true

      # Verify session works
      get "/api/grid/current_hackr", as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["logged_in"]).to be true

      # Admin disables the account
      hackr.update!(login_disabled: true)

      # Next request should fail auth
      get "/api/grid/current_hackr", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/totp/verify" do
    let(:secret) { ROTP::Base32.random }

    before do
      hackr.otp_secret = secret
      hackr.otp_required_for_login = true
      hackr.save!(validate: false)
      hackr.generate_backup_codes!
    end

    it "blocks disabled hackr during 2FA verification" do
      # Start login (sets pending session)
      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}, as: :json
      expect(response.parsed_body["requires_totp"]).to be true

      # Admin disables account between password and TOTP steps
      hackr.update!(login_disabled: true)

      # TOTP verify should reject
      code = ROTP::TOTP.new(secret).now
      post "/api/totp/verify", params: {code: code}, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to include("disabled")
    end
  end
end
