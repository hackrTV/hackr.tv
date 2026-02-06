require "rails_helper"

RSpec.describe GridVerificationToken, type: :model do
  let(:hackr) { create(:grid_hackr, email: "test@example.com") }

  def create_token(**attrs)
    GridVerificationToken.create!(
      {grid_hackr: hackr, purpose: "password_reset", ip_address: "127.0.0.1"}.merge(attrs)
    )
  end

  describe "validations" do
    it "requires a purpose" do
      token = GridVerificationToken.new(grid_hackr: hackr, purpose: nil, ip_address: "127.0.0.1")
      expect(token).not_to be_valid
      expect(token.errors[:purpose]).to include("can't be blank")
    end

    it "requires purpose to be in the allowed list" do
      token = GridVerificationToken.new(grid_hackr: hackr, purpose: "invalid", ip_address: "127.0.0.1")
      expect(token).not_to be_valid
      expect(token.errors[:purpose]).to include("is not included in the list")
    end

    it "accepts password_reset purpose" do
      token = GridVerificationToken.new(grid_hackr: hackr, purpose: "password_reset", ip_address: "127.0.0.1")
      expect(token).to be_valid
    end

    it "requires a grid_hackr" do
      token = GridVerificationToken.new(grid_hackr: nil, purpose: "password_reset", ip_address: "127.0.0.1")
      expect(token).not_to be_valid
    end
  end

  describe "before_create callbacks" do
    it "generates a token" do
      token = create_token
      expect(token.token).to be_present
      expect(token.token.length).to eq(43)
    end

    it "sets expiration to 24 hours from now" do
      token = create_token
      expect(token.expires_at).to be_within(1.second).of(24.hours.from_now)
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      token = create_token
      token.update_column(:expires_at, 1.hour.ago)
      expect(token.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      token = create_token
      expect(token.expired?).to be false
    end
  end

  describe "#used?" do
    it "returns true when used_at is set" do
      token = create_token
      token.update!(used_at: Time.current)
      expect(token.used?).to be true
    end

    it "returns false when used_at is nil" do
      token = create_token
      expect(token.used?).to be false
    end
  end

  describe "#valid_for_use?" do
    it "returns true when not expired and not used" do
      token = create_token
      expect(token.valid_for_use?).to be true
    end

    it "returns false when expired" do
      token = create_token
      token.update_column(:expires_at, 1.hour.ago)
      expect(token.valid_for_use?).to be false
    end

    it "returns false when used" do
      token = create_token
      token.update!(used_at: Time.current)
      expect(token.valid_for_use?).to be false
    end
  end

  describe "#mark_used!" do
    it "sets used_at to current time" do
      token = create_token
      token.mark_used!
      expect(token.used_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "scopes" do
    describe ".valid" do
      it "returns only non-expired, non-used tokens" do
        valid_token = create_token

        expired_token = create_token
        expired_token.update_column(:expires_at, 1.hour.ago)

        used_token = create_token
        used_token.update!(used_at: Time.current)

        expect(GridVerificationToken.valid).to include(valid_token)
        expect(GridVerificationToken.valid).not_to include(expired_token)
        expect(GridVerificationToken.valid).not_to include(used_token)
      end
    end

    describe ".for_purpose" do
      it "returns tokens for the specified purpose" do
        token = create_token(purpose: "password_reset")

        expect(GridVerificationToken.for_purpose("password_reset")).to include(token)
      end
    end
  end

  describe "associations" do
    it "belongs to a grid_hackr" do
      token = create_token
      expect(token.grid_hackr).to eq(hackr)
    end
  end
end
