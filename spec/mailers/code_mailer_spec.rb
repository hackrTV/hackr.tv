require "rails_helper"

RSpec.describe CodeMailer, type: :mailer do
  describe "#token_expired" do
    let(:error_message) { "401 Unauthorized - Bad credentials" }
    let(:mail) { described_class.token_expired(error_message) }

    it "sends to x@hackr.tv" do
      expect(mail.to).to eq(["x@hackr.tv"])
    end

    it "sends from null@beacon.hackr.tv" do
      expect(mail.from).to eq(["null@beacon.hackr.tv"])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("hackr.tv Code Sync: GitHub token expired")
    end

    it "includes the error message in the body" do
      expect(mail.body.encoded).to include(error_message)
    end

    it "includes instructions to regenerate the token" do
      expect(mail.body.encoded).to include("GitHub Token Settings")
      expect(mail.body.encoded).to include("public_repo")
    end
  end
end
