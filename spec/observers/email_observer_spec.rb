require "rails_helper"

RSpec.describe EmailObserver do
  let(:hackr) { create(:grid_hackr, email: "hackr@example.com") }

  describe ".delivered_email" do
    it "creates a SentEmail record when a password reset email is delivered" do
      token = GridVerificationToken.create!(
        grid_hackr: hackr,
        purpose: "password_reset",
        ip_address: "127.0.0.1"
      )

      expect {
        GridMailer.password_reset(token).deliver_now
      }.to change(SentEmail, :count).by(1)

      sent = SentEmail.last
      expect(sent.to).to eq("hackr@example.com")
      expect(sent.from).to eq("null@beacon.hackr.tv")
      expect(sent.subject).to eq("Password reset for THE PULSE GRID")
      expect(sent.mailer_class).to eq("GridMailer")
      expect(sent.mailer_action).to eq("password_reset")
      expect(sent.emailable).to eq(hackr)
    end

    it "creates a SentEmail record for registration verification without emailable" do
      token = GridRegistrationToken.create!(
        email: "new@example.com",
        ip_address: "127.0.0.1"
      )

      expect {
        GridMailer.registration_verification(token).deliver_now
      }.to change(SentEmail, :count).by(1)

      sent = SentEmail.last
      expect(sent.to).to eq("new@example.com")
      expect(sent.subject).to eq("Complete your registration on THE PULSE GRID")
      expect(sent.mailer_class).to eq("GridMailer")
      expect(sent.mailer_action).to eq("registration_verification")
      expect(sent.emailable).to be_nil
    end

    it "creates a SentEmail record for email change verification" do
      token = GridVerificationToken.create!(
        grid_hackr: hackr,
        purpose: "email_change",
        metadata: {"new_email" => "new@example.com"},
        ip_address: "127.0.0.1"
      )

      expect {
        GridMailer.email_change_verification(token).deliver_now
      }.to change(SentEmail, :count).by(1)

      sent = SentEmail.last
      expect(sent.to).to eq("new@example.com")
      expect(sent.mailer_action).to eq("email_change_verification")
      expect(sent.emailable).to eq(hackr)
    end

    it "creates a SentEmail record for email change notification" do
      expect {
        GridMailer.email_change_notification(hackr, "old@example.com").deliver_now
      }.to change(SentEmail, :count).by(1)

      sent = SentEmail.last
      expect(sent.to).to eq("old@example.com")
      expect(sent.mailer_action).to eq("email_change_notification")
      expect(sent.emailable).to eq(hackr)
    end

    it "stores text and html body content" do
      token = GridVerificationToken.create!(
        grid_hackr: hackr,
        purpose: "password_reset",
        ip_address: "127.0.0.1"
      )

      GridMailer.password_reset(token).deliver_now

      sent = SentEmail.last
      expect(sent.text_body).to be_present.or(be_nil)
      expect(sent.html_body).to be_present.or(be_nil)
      expect(sent.text_body.present? || sent.html_body.present?).to be true
    end

    it "does not raise if recording fails" do
      allow(SentEmail).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      token = GridVerificationToken.create!(
        grid_hackr: hackr,
        purpose: "password_reset",
        ip_address: "127.0.0.1"
      )

      expect {
        GridMailer.password_reset(token).deliver_now
      }.not_to raise_error
    end
  end
end
