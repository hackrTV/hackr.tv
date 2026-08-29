require "rails_helper"

# Server-rendered email change (Hotwire migration Phase 2): request from
# the identity page, then the confirm-button landing page. The explicit
# confirm POST (instead of the SPA's confirm-on-mount) keeps mail-scanner
# prefetchers from burning the single-use token.
RSpec.describe "Grid email change pages", type: :request do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid", email: "old@example.com") }

  def log_in!
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  describe "POST /grid/identity/email_change" do
    it "requires login" do
      post "/grid/identity/email_change", params: {new_email: "new@example.com"}

      expect(response).to redirect_to("/grid/login")
    end

    it "creates a token and mails the new address" do
      log_in!

      expect {
        post "/grid/identity/email_change", params: {new_email: "New@Example.com"}
      }.to change(GridVerificationToken, :count).by(1)
        .and have_enqueued_mail(GridMailer, :email_change_verification)

      expect(response).to redirect_to("/grid/identity")
      expect(flash[:x_email_notice]).to include("Verification email sent to new@example.com")
      expect(GridVerificationToken.last.new_email).to eq("new@example.com")
    end

    it "rejects the current email and taken emails" do
      create(:grid_hackr, email: "taken@example.com")
      log_in!

      post "/grid/identity/email_change", params: {new_email: "old@example.com"}
      expect(flash[:x_email_error]).to eq("New email must be different from your current email.")

      post "/grid/identity/email_change", params: {new_email: "taken@example.com"}
      expect(flash[:x_email_error]).to eq("This email address is already in use.")

      post "/grid/identity/email_change", params: {new_email: "bad"}
      expect(flash[:x_email_error]).to eq("Please enter a valid email address.")
    end
  end

  describe "GET /grid/confirm_email_change/:token" do
    let(:token) do
      GridVerificationToken.create!(grid_hackr: hackr, purpose: "email_change", metadata: {new_email: "new@example.com"})
    end

    it "renders the confirm button without consuming the token" do
      get "/grid/confirm_email_change/#{token.token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("CONFIRM EMAIL CHANGE")
      expect(response.body).to include("new@example.com")
      expect(token.reload).not_to be_used
      expect(hackr.reload.email).to eq("old@example.com")
    end

    it "shows the failure panel for bad tokens" do
      get "/grid/confirm_email_change/nope"
      expect(response.body).to include("Invalid verification token.")

      token.mark_used!
      get "/grid/confirm_email_change/#{token.token}"
      expect(response.body).to include("This verification link has already been used.")
    end
  end

  describe "POST /grid/confirm_email_change/:token" do
    let!(:token) do
      GridVerificationToken.create!(grid_hackr: hackr, purpose: "email_change", metadata: {new_email: "new@example.com"})
    end

    it "updates the email, notifies the old address, and marks the token used" do
      expect {
        post "/grid/confirm_email_change/#{token.token}"
      }.to have_enqueued_mail(GridMailer, :email_change_notification)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("EMAIL UPDATED")
      expect(hackr.reload.email).to eq("new@example.com")
      expect(token.reload).to be_used
    end

    it "fails when the address was taken in the meantime" do
      create(:grid_hackr, email: "new@example.com")

      post "/grid/confirm_email_change/#{token.token}"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("This email address is already in use.")
      expect(hackr.reload.email).to eq("old@example.com")
    end

    it "fails for an expired token" do
      token.update!(expires_at: 1.hour.ago)

      post "/grid/confirm_email_change/#{token.token}"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("This verification link has expired.")
    end
  end
end
