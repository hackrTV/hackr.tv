# == Schema Information
#
# Table name: grid_registration_tokens
# Database name: primary
#
#  id         :integer          not null, primary key
#  email      :string           not null
#  expires_at :datetime         not null
#  ip_address :string
#  token      :string           not null
#  used_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_grid_registration_tokens_on_email  (email)
#  index_grid_registration_tokens_on_token  (token) UNIQUE
#
require "rails_helper"

RSpec.describe GridRegistrationToken, type: :model do
  describe "validations" do
    it "requires an email" do
      token = GridRegistrationToken.new(email: nil, ip_address: "127.0.0.1")
      expect(token).not_to be_valid
      expect(token.errors[:email]).to include("can't be blank")
    end

    it "requires a valid email format" do
      token = GridRegistrationToken.new(email: "not-an-email", ip_address: "127.0.0.1")
      expect(token).not_to be_valid
      expect(token.errors[:email]).to include("is invalid")
    end

    it "accepts valid email format" do
      token = GridRegistrationToken.new(email: "test@example.com", ip_address: "127.0.0.1")
      expect(token).to be_valid
    end
  end

  describe "before_create callbacks" do
    it "generates a token" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      expect(token.token).to be_present
      expect(token.token.length).to eq(43) # urlsafe_base64(32) produces 43 chars
    end

    it "sets expiration to 24 hours from now" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      expect(token.expires_at).to be_within(1.second).of(24.hours.from_now)
    end
  end

  describe "email normalization" do
    it "normalizes email to lowercase" do
      token = GridRegistrationToken.create!(email: "TEST@EXAMPLE.COM", ip_address: "127.0.0.1")
      expect(token.email).to eq("test@example.com")
    end

    it "strips whitespace from email" do
      token = GridRegistrationToken.create!(email: "  test@example.com  ", ip_address: "127.0.0.1")
      expect(token.email).to eq("test@example.com")
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      token.update_column(:expires_at, 1.hour.ago)
      expect(token.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      expect(token.expired?).to be false
    end
  end

  describe "#used?" do
    it "returns true when used_at is set" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      token.update!(used_at: Time.current)
      expect(token.used?).to be true
    end

    it "returns false when used_at is nil" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      expect(token.used?).to be false
    end
  end

  describe "#valid_for_use?" do
    it "returns true when not expired and not used" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      expect(token.valid_for_use?).to be true
    end

    it "returns false when expired" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      token.update_column(:expires_at, 1.hour.ago)
      expect(token.valid_for_use?).to be false
    end

    it "returns false when used" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      token.update!(used_at: Time.current)
      expect(token.valid_for_use?).to be false
    end
  end

  describe "#mark_used!" do
    it "sets used_at to current time" do
      token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
      token.mark_used!
      expect(token.used_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "scopes" do
    describe ".valid" do
      it "returns only non-expired, non-used tokens" do
        valid_token = GridRegistrationToken.create!(email: "valid@example.com", ip_address: "127.0.0.1")

        expired_token = GridRegistrationToken.create!(email: "expired@example.com", ip_address: "127.0.0.1")
        expired_token.update_column(:expires_at, 1.hour.ago)

        used_token = GridRegistrationToken.create!(email: "used@example.com", ip_address: "127.0.0.1")
        used_token.update!(used_at: Time.current)

        expect(GridRegistrationToken.valid).to include(valid_token)
        expect(GridRegistrationToken.valid).not_to include(expired_token)
        expect(GridRegistrationToken.valid).not_to include(used_token)
      end
    end

    describe ".for_email" do
      it "returns tokens for the specified email" do
        token1 = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
        token2 = GridRegistrationToken.create!(email: "other@example.com", ip_address: "127.0.0.1")

        expect(GridRegistrationToken.for_email("test@example.com")).to include(token1)
        expect(GridRegistrationToken.for_email("test@example.com")).not_to include(token2)
      end

      it "normalizes the email before searching" do
        token = GridRegistrationToken.create!(email: "test@example.com", ip_address: "127.0.0.1")
        expect(GridRegistrationToken.for_email("TEST@EXAMPLE.COM")).to include(token)
      end
    end
  end
end
