require "rails_helper"

RSpec.describe Api::GridController, type: :controller do
  describe "POST #register (email verification request)" do
    before do
      stub_const("APP_SETTINGS", {prerelease_mode: nil}.freeze)
    end

    context "with valid email" do
      it "returns success status" do
        post :register, params: {email: "test@example.com"}, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["message"]).to include("Verification email sent")
      end

      it "creates a registration token" do
        expect {
          post :register, params: {email: "test@example.com"}, format: :json
        }.to change(GridRegistrationToken, :count).by(1)
      end

      it "sends a verification email" do
        expect {
          post :register, params: {email: "test@example.com"}, format: :json
        }.to have_enqueued_mail(GridMailer, :registration_verification)
      end

      it "normalizes email to lowercase" do
        post :register, params: {email: "TEST@EXAMPLE.COM"}, format: :json

        token = GridRegistrationToken.last
        expect(token.email).to eq("test@example.com")
      end

      it "logs the registration email request" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/\[AUTH\] Registration email sent: email=test@example.com ip=/)

        post :register, params: {email: "test@example.com"}, format: :json
      end
    end

    context "with invalid email" do
      it "rejects empty email" do
        post :register, params: {email: ""}, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("Email address is required")
      end

      it "rejects invalid email format" do
        post :register, params: {email: "not-an-email"}, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("valid email address")
      end
    end

    context "with already registered email" do
      before do
        create(:grid_hackr, email: "taken@example.com")
      end

      it "returns error for duplicate email" do
        post :register, params: {email: "taken@example.com"}, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("already registered")
      end
    end
  end

  describe "GET #verify_token" do
    context "with valid token" do
      let!(:token) { GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1") }

      it "returns valid status with email" do
        get :verify_token, params: {token: token.token}, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["valid"]).to eq(true)
        expect(json["email"]).to eq("test@example.com")
      end
    end

    context "with invalid token" do
      it "returns invalid status" do
        get :verify_token, params: {token: "nonexistent-token"}, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["valid"]).to eq(false)
        expect(json["error"]).to include("Invalid verification link")
      end
    end

    context "with expired token" do
      let!(:token) { GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1") }

      before do
        token.update_column(:expires_at, 1.hour.ago)
      end

      it "returns invalid status" do
        get :verify_token, params: {token: token.token}, format: :json

        json = JSON.parse(response.body)
        expect(json["valid"]).to eq(false)
        expect(json["error"]).to include("expired")
      end
    end

    context "with used token" do
      let!(:token) { GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1") }

      before do
        token.update!(used_at: Time.current)
      end

      it "returns invalid status" do
        get :verify_token, params: {token: token.token}, format: :json

        json = JSON.parse(response.body)
        expect(json["valid"]).to eq(false)
        expect(json["error"]).to include("already been used")
      end
    end
  end

  describe "POST #complete_registration" do
    let!(:zone) { create(:grid_zone, slug: "hackr_tv_central") }
    let!(:room) { create(:grid_room, grid_zone: zone, room_type: "hub") }
    let!(:token) { GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1") }

    context "with valid token and valid params" do
      it "creates a new GridHackr" do
        expect {
          post :complete_registration, params: {
            token: token.token,
            hackr_alias: "NewHackr",
            password: "hackthegrid",
            password_confirmation: "hackthegrid"
          }, format: :json
        }.to change(GridHackr, :count).by(1)
      end

      it "returns success with hackr data" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "NewHackr",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["hackr"]["hackr_alias"]).to eq("NewHackr")
      end

      it "sets the email on the hackr" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "NewHackr",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        hackr = GridHackr.last
        expect(hackr.email).to eq("test@example.com")
      end

      it "marks the token as used" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "NewHackr",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        expect(token.reload.used_at).to be_present
      end

      it "logs the user in" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "NewHackr",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        expect(session[:grid_hackr_id]).to eq(GridHackr.last.id)
      end

      it "logs successful registration" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/\[AUTH\] Registration completed: hackr_alias=NewHackr email=test@example.com ip=/)

        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "NewHackr",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json
      end
    end

    context "with invalid token" do
      it "returns error for nonexistent token" do
        post :complete_registration, params: {
          token: "bad-token",
          hackr_alias: "NewHackr",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("Invalid verification token")
      end
    end

    context "with used token" do
      before do
        token.update!(used_at: Time.current)
      end

      it "returns error" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "NewHackr",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("already been used")
      end
    end

    context "with invalid hackr params" do
      it "rejects short alias" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "ABC",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("must be at least #{GridHackr::MINIMUM_ALIAS_LENGTH} characters")
      end

      it "rejects reserved aliases" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "administrator",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("is reserved and cannot be used")
      end

      it "rejects password mismatch" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "NewHackr",
          password: "hackthegrid",
          password_confirmation: "differenthackr"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("doesn't match")
      end

      it "does not mark token as used if registration fails" do
        post :complete_registration, params: {
          token: token.token,
          hackr_alias: "ABC",
          password: "hackthegrid",
          password_confirmation: "hackthegrid"
        }, format: :json

        expect(token.reload.used_at).to be_nil
      end
    end
  end

  describe "POST #request_password_reset" do
    let!(:hackr) { create(:grid_hackr, email: "reset@example.com") }

    context "when logged in" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns success" do
        post :request_password_reset, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["message"]).to include("Password reset email sent")
      end

      it "creates a verification token with password_reset purpose" do
        expect {
          post :request_password_reset, format: :json
        }.to change(GridVerificationToken, :count).by(1)

        token = GridVerificationToken.last
        expect(token.grid_hackr_id).to eq(hackr.id)
        expect(token.purpose).to eq("password_reset")
      end

      it "sends a password reset email" do
        expect {
          post :request_password_reset, format: :json
        }.to have_enqueued_mail(GridMailer, :password_reset)
      end

      it "logs the password reset request" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/\[AUTH\] Password reset email sent: hackr_alias=#{hackr.hackr_alias} ip=/)

        post :request_password_reset, format: :json
      end
    end

    context "when not logged in" do
      it "returns unauthorized" do
        post :request_password_reset, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #reset_password" do
    let!(:hackr) { create(:grid_hackr, email: "reset@example.com", password: "oldpassword") }
    let!(:token) { GridVerificationToken.create!(grid_hackr: hackr, purpose: "password_reset", ip_address: "127.0.0.1") }

    context "when logged in with valid token" do
      before { session[:grid_hackr_id] = hackr.id }

      it "updates the password" do
        post :reset_password, params: {
          token: token.token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(hackr.reload.authenticate("newpassword123")).to be_truthy
      end

      it "marks the token as used" do
        post :reset_password, params: {
          token: token.token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }, format: :json

        expect(token.reload.used_at).to be_present
      end

      it "logs the password reset" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/\[AUTH\] Password reset completed: hackr_alias=#{hackr.hackr_alias} ip=/)

        post :reset_password, params: {
          token: token.token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }, format: :json
      end

      it "rejects password mismatch" do
        post :reset_password, params: {
          token: token.token,
          password: "newpassword123",
          password_confirmation: "differentpassword"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("doesn't match")
      end
    end

    context "with invalid token" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns error for nonexistent token" do
        post :reset_password, params: {
          token: "bad-token",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("Invalid reset token")
      end
    end

    context "with expired token" do
      before do
        session[:grid_hackr_id] = hackr.id
        token.update_column(:expires_at, 1.hour.ago)
      end

      it "returns error" do
        post :reset_password, params: {
          token: token.token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("expired")
      end
    end

    context "with used token" do
      before do
        session[:grid_hackr_id] = hackr.id
        token.update!(used_at: Time.current)
      end

      it "returns error" do
        post :reset_password, params: {
          token: token.token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("already been used")
      end
    end

    context "with token belonging to a different hackr" do
      let!(:other_hackr) { create(:grid_hackr, email: "other@example.com") }

      before { session[:grid_hackr_id] = other_hackr.id }

      it "returns error" do
        post :reset_password, params: {
          token: token.token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("does not belong to your account")
      end
    end

    context "when not logged in" do
      it "returns unauthorized" do
        post :reset_password, params: {
          token: token.token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #login" do
    let!(:hackr) { create(:grid_hackr, hackr_alias: "TestHackr", password: "hackthegrid") }

    context "when prerelease mode is active" do
      before do
        stub_const("APP_SETTINGS", {prerelease_mode: "alpha", prerelease_banner_text: "Test banner"}.freeze)
      end

      it "still allows login for existing users" do
        post :login, params: {
          hackr_alias: "TestHackr",
          password: "hackthegrid"
        }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
      end
    end

    describe "auth logging" do
      it "logs successful login" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/\[AUTH\] Login success: hackr_alias=TestHackr ip=/)

        post :login, params: {
          hackr_alias: "TestHackr",
          password: "hackthegrid"
        }, format: :json
      end

      it "logs failed login with invalid password" do
        allow(Rails.logger).to receive(:warn).and_call_original
        expect(Rails.logger).to receive(:warn).with(/\[AUTH\] Login failed: attempted_alias=TestHackr reason=invalid_password ip=/)

        post :login, params: {
          hackr_alias: "TestHackr",
          password: "wrongpassword"
        }, format: :json
      end

      it "logs failed login with unknown alias" do
        allow(Rails.logger).to receive(:warn).and_call_original
        expect(Rails.logger).to receive(:warn).with(/\[AUTH\] Login failed: attempted_alias=UnknownHackr reason=unknown_alias ip=/)

        post :login, params: {
          hackr_alias: "UnknownHackr",
          password: "hackthegrid"
        }, format: :json
      end

      it "truncates long alias attempts in logs" do
        long_alias = "A" * 100
        allow(Rails.logger).to receive(:warn).and_call_original
        expect(Rails.logger).to receive(:warn).with(/attempted_alias=A{47}\.\.\./)

        post :login, params: {
          hackr_alias: long_alias,
          password: "hackthegrid"
        }, format: :json
      end
    end
  end
end
