require "rails_helper"

RSpec.describe "Api::TotpController", type: :request do
  let(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  def login_as(h)
    post "/api/grid/login", params: {hackr_alias: h.hackr_alias, password: "hackthegrid"}, as: :json
  end

  describe "GET /api/totp/status" do
    it "returns 401 when not logged in" do
      get "/api/totp/status", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns disabled status for hackr without 2FA" do
      login_as(hackr)
      get "/api/totp/status", as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["enabled"]).to be false
      expect(body["backup_codes_remaining"]).to eq(0)
    end
  end

  describe "POST /api/totp/setup" do
    it "returns secret and QR SVG" do
      login_as(hackr)
      post "/api/totp/setup", as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["success"]).to be true
      expect(body["secret"]).to be_present
      expect(body["qr_svg"]).to include("<svg")
    end

    it "returns 401 when not logged in" do
      post "/api/totp/setup", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/totp/enable" do
    it "enables 2FA and returns backup codes" do
      login_as(hackr)
      post "/api/totp/setup", as: :json
      secret = response.parsed_body["secret"]

      totp = ROTP::TOTP.new(secret)
      post "/api/totp/enable", params: {
        password: "hackthegrid",
        otp_secret: secret,
        code: totp.now
      }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["success"]).to be true
      expect(body["backup_codes"].length).to eq(8)
      expect(hackr.reload.otp_required_for_login?).to be true
    end

    it "rejects wrong password" do
      login_as(hackr)
      post "/api/totp/setup", as: :json
      secret = response.parsed_body["secret"]

      post "/api/totp/enable", params: {
        password: "wrong",
        otp_secret: secret,
        code: ROTP::TOTP.new(secret).now
      }, as: :json

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

    it "completes login with valid TOTP code" do
      # Login sets pending session
      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}, as: :json
      expect(response.parsed_body["requires_totp"]).to be true

      # Verify TOTP
      code = ROTP::TOTP.new(secret).now
      post "/api/totp/verify", params: {code: code}, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["success"]).to be true
      expect(body["hackr"]["hackr_alias"]).to eq(hackr.hackr_alias)
    end

    it "completes login with valid backup code" do
      codes = hackr.generate_backup_codes!

      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}, as: :json
      post "/api/totp/verify", params: {code: codes.first}, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["success"]).to be true
    end

    it "rejects invalid code" do
      post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}, as: :json
      post "/api/totp/verify", params: {code: "000000"}, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects when no pending session" do
      post "/api/totp/verify", params: {code: "123456"}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to include("No pending")
    end
  end

  describe "DELETE /api/totp/disable" do
    let(:secret) { ROTP::Base32.random }

    before do
      hackr.otp_secret = secret
      hackr.otp_required_for_login = true
      hackr.save!(validate: false)
      @backup_codes = hackr.generate_backup_codes!
      login_as(hackr)
      # Complete 2FA verification using a backup code to preserve TOTP freshness
      post "/api/totp/verify", params: {code: @backup_codes.first}, as: :json
    end

    it "disables 2FA with valid password and code" do
      code = ROTP::TOTP.new(secret).now
      delete "/api/totp/disable", params: {password: "hackthegrid", code: code}, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["success"]).to be true
      expect(hackr.reload.otp_required_for_login?).to be false
    end
  end

  describe "POST /api/totp/regenerate_backup_codes" do
    let(:secret) { ROTP::Base32.random }

    before do
      hackr.otp_secret = secret
      hackr.otp_required_for_login = true
      hackr.save!(validate: false)
      @backup_codes = hackr.generate_backup_codes!
      login_as(hackr)
      post "/api/totp/verify", params: {code: @backup_codes.first}, as: :json
    end

    it "returns new backup codes" do
      code = ROTP::TOTP.new(secret).now
      post "/api/totp/regenerate_backup_codes", params: {password: "hackthegrid", code: code}, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["success"]).to be true
      expect(body["backup_codes"].length).to eq(8)
    end

    it "rejects wrong password" do
      code = ROTP::TOTP.new(secret).now
      post "/api/totp/regenerate_backup_codes", params: {password: "wrong", code: code}, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/totp/admin_reset" do
    let(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
    let(:target) { create(:grid_hackr, password: "hackthegrid") }

    before do
      target.update_columns(otp_required_for_login: true)
      target.otp_secret = ROTP::Base32.random
      target.save!(validate: false)
    end

    it "clears 2FA for target hackr" do
      login_as(admin)
      post "/api/totp/admin_reset", params: {hackr_alias: target.hackr_alias}, as: :json

      expect(response).to have_http_status(:ok)
      expect(target.reload.otp_required_for_login?).to be false
    end

    it "rejects non-admin" do
      login_as(hackr)
      post "/api/totp/admin_reset", params: {hackr_alias: target.hackr_alias}, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
