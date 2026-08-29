require "rails_helper"

# Server-rendered password flows (Hotwire migration Phase 2): forgot,
# token reset, and the logged-in reset-credentials action.
RSpec.describe "Grid password pages", type: :request do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid", email: "op@example.com") }

  describe "GET /grid/forgot_password" do
    it "renders the recovery form" do
      get "/grid/forgot_password"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("RECOVER ACCESS")
      expect(response.body).to include("SEND RESET LINK")
    end
  end

  describe "POST /grid/forgot_password" do
    it "creates a token and mails a known email" do
      expect {
        post "/grid/forgot_password", params: {email: "op@example.com"}
      }.to change(GridVerificationToken, :count).by(1)
        .and have_enqueued_mail(GridMailer, :password_reset)

      expect(response).to redirect_to("/grid/forgot_password")
      follow_redirect!
      expect(response.body).to include("CHECK YOUR INBOX")
      expect(response.body).to include("op@example.com")
    end

    it "shows the same panel for an unknown email (no enumeration)" do
      expect {
        post "/grid/forgot_password", params: {email: "ghost@example.com"}
      }.not_to change(GridVerificationToken, :count)

      expect(response).to redirect_to("/grid/forgot_password")
      follow_redirect!
      expect(response.body).to include("CHECK YOUR INBOX")
      expect(response.body).to include("ghost@example.com")
    end
  end

  describe "GET /grid/reset_password/:token" do
    let(:token) { GridVerificationToken.create!(grid_hackr: hackr, purpose: "password_reset") }

    it "renders the reset form for a valid token" do
      get "/grid/reset_password/#{token.token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ENTER NEW CREDENTIALS")
      expect(response.body).to include("NEW PASSWORD:")
    end

    it "shows the failure panel for unknown, used, and expired tokens" do
      get "/grid/reset_password/nope"
      expect(response.body).to include("Invalid reset token.")

      token.mark_used!
      get "/grid/reset_password/#{token.token}"
      expect(response.body).to include("This reset link has already been used.")

      fresh = GridVerificationToken.create!(grid_hackr: hackr, purpose: "password_reset")
      fresh.update!(expires_at: 1.hour.ago)
      get "/grid/reset_password/#{fresh.token}"
      expect(response.body).to include("This reset link has expired.")
    end

    it "rejects tokens with a different purpose" do
      other = GridVerificationToken.create!(grid_hackr: hackr, purpose: "email_change", metadata: {new_email: "x@example.com"})

      get "/grid/reset_password/#{other.token}"

      expect(response.body).to include("Invalid reset token.")
    end
  end

  describe "POST /grid/reset_password/:token" do
    let!(:token) { GridVerificationToken.create!(grid_hackr: hackr, purpose: "password_reset") }

    it "updates the password, marks the token used, and lands on login" do
      post "/grid/reset_password/#{token.token}", params: {
        password: "new-passphrase-9", password_confirmation: "new-passphrase-9"
      }

      expect(response).to redirect_to("/grid/login")
      expect(flash[:success]).to include("Password updated successfully.")
      expect(token.reload).to be_used
      expect(hackr.reload.authenticate("new-passphrase-9")).to be_truthy
    end

    it "re-renders with model errors on mismatch" do
      post "/grid/reset_password/#{token.token}", params: {
        password: "new-passphrase-9", password_confirmation: "different"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Password update failed:")
      expect(token.reload).not_to be_used
    end

    it "shows the failure panel for a used token" do
      token.mark_used!

      post "/grid/reset_password/#{token.token}", params: {
        password: "new-passphrase-9", password_confirmation: "new-passphrase-9"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("This reset link has already been used.")
    end
  end

  describe "POST /grid/identity/password_reset" do
    it "requires login" do
      post "/grid/identity/password_reset"

      expect(response).to redirect_to("/grid/login")
    end

    it "mails a reset link to the logged-in hackr" do
      post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}

      expect {
        post "/grid/identity/password_reset"
      }.to have_enqueued_mail(GridMailer, :password_reset)

      expect(response).to redirect_to("/grid/identity")
      expect(flash[:x_password_notice]).to include("Password reset email sent.")
    end

    it "errors when no email is on file" do
      hackr.update!(email: nil)
      post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}

      post "/grid/identity/password_reset"

      expect(response).to redirect_to("/grid/identity")
      expect(flash[:x_password_error]).to include("No email address on file.")
    end
  end
end
