require "rails_helper"

# Server-rendered TOTP management (Hotwire migration Phase 2).
RSpec.describe "Grid two-factor pages", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def enable_totp!(secret = ROTP::Base32.random)
    hackr.update!(otp_secret: secret, otp_required_for_login: true)
    secret
  end

  describe "GET /grid/identity/two-factor" do
    it "requires login" do
      get "/grid/identity/two-factor"
      expect(response).to redirect_to("/grid/login")
    end

    it "renders the inactive state with an enable link" do
      log_in!
      get "/grid/identity/two-factor"

      expect(response.body).to include("STATUS:")
      expect(response.body).to include("INACTIVE")
      expect(response.body).to include("ENABLE TWO-FACTOR AUTH")
    end
  end

  describe "enable flow" do
    before { log_in! }

    it "shows a fresh secret + QR on the setup page" do
      get "/grid/identity/two-factor/setup"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("STEP 1: SCAN QR CODE")
      expect(response.body).to include("<svg") # QR
      expect(response.body).to match(/name="otp_secret"[^>]*value="[A-Z2-7]+"/)
    end

    it "redirects setup away when already enabled" do
      enable_totp!

      get "/grid/identity/two-factor/setup"

      expect(response).to redirect_to("/grid/identity/two-factor")
    end

    it "enables 2FA and shows backup codes exactly once" do
      secret = ROTP::Base32.random

      post "/grid/identity/two-factor/enable", params: {
        password: "hackthegrid", otp_secret: secret, code: ROTP::TOTP.new(secret).now
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SAVE THESE BACKUP CODES")
      expect(hackr.reload.otp_required_for_login).to be(true)
      expect(hackr.otp_secret).to eq(secret)
      expect(hackr.otp_backup_code_digests.length).to eq(8)
    end

    it "re-renders setup with the same staged secret on a wrong password" do
      secret = ROTP::Base32.random

      post "/grid/identity/two-factor/enable", params: {
        password: "wrong", otp_secret: secret, code: ROTP::TOTP.new(secret).now
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Password incorrect.")
      expect(response.body).to include(%(value="#{secret}"))
      expect(hackr.reload.otp_required_for_login).to be(false)
    end

    it "re-renders setup on an invalid code" do
      secret = ROTP::Base32.random

      post "/grid/identity/two-factor/enable", params: {
        password: "hackthegrid", otp_secret: secret, code: "000000"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Invalid TOTP code. Try again.")
      expect(hackr.reload.otp_required_for_login).to be(false)
    end
  end

  describe "with 2FA active" do
    let(:secret) { ROTP::Base32.random }

    before do
      enable_totp!(secret)
      hackr.generate_backup_codes!
      # 2FA-gated login
      post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
      post "/grid/login/verify", params: {totp_code: ROTP::TOTP.new(secret).now}
    end

    it "renders the active state" do
      get "/grid/identity/two-factor"

      expect(response.body).to include("ACTIVE")
      expect(response.body).to include("BACKUP CODES REMAINING:")
      expect(response.body).to include("REGENERATE BACKUP CODES")
      expect(response.body).to include("DISABLE TWO-FACTOR AUTH")
    end

    it "renders the disable and regenerate confirmation forms via ?mode=" do
      get "/grid/identity/two-factor", params: {mode: "disable"}
      expect(response.body).to include("CONFIRM DISABLE")

      get "/grid/identity/two-factor", params: {mode: "regenerate"}
      expect(response.body).to include("This will invalidate all existing backup codes")
    end

    it "disables 2FA with password + code" do
      # travel past the enable/login verifications so the same 30s TOTP
      # window isn't replay-blocked by otp_last_used_at
      travel 90.seconds do
        delete "/grid/identity/two-factor", params: {
          password: "hackthegrid", code: ROTP::TOTP.new(secret).now
        }
      end

      expect(response).to redirect_to("/grid/identity/two-factor")
      expect(flash[:x_tf_notice]).to eq("Two-factor authentication disabled.")
      expect(hackr.reload.otp_required_for_login).to be(false)
      expect(hackr.otp_secret).to be_nil
    end

    it "re-renders the disable form on a wrong password" do
      travel 90.seconds do
        delete "/grid/identity/two-factor", params: {
          password: "wrong", code: ROTP::TOTP.new(secret).now
        }
      end

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Password incorrect.")
      expect(response.body).to include("CONFIRM DISABLE")
      expect(hackr.reload.otp_required_for_login).to be(true)
    end

    it "regenerates backup codes and invalidates the old set" do
      old_digests = hackr.reload.otp_backup_code_digests

      travel 90.seconds do
        post "/grid/identity/two-factor/backup_codes", params: {
          password: "hackthegrid", code: ROTP::TOTP.new(secret).now
        }
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SAVE THESE BACKUP CODES")
      expect(hackr.reload.otp_backup_code_digests.length).to eq(8)
      expect(hackr.otp_backup_code_digests).not_to eq(old_digests)
    end
  end
end
