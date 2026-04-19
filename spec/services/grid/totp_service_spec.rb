require "rails_helper"

RSpec.describe Grid::TotpService do
  let(:hackr) { create(:grid_hackr, password: "hackthegrid") }
  let(:service) { described_class.new(hackr) }

  describe "#generate_setup_data" do
    it "returns secret, provisioning_uri, and qr_svg" do
      data = service.generate_setup_data

      expect(data[:secret]).to be_present
      expect(data[:provisioning_uri]).to include("otpauth://totp/")
      expect(data[:provisioning_uri]).to include(hackr.hackr_alias)
      expect(data[:qr_svg]).to include("<svg")
    end

    it "raises AlreadyEnabled when 2FA is active" do
      hackr.update_columns(otp_required_for_login: true)

      expect { service.generate_setup_data }
        .to raise_error(Grid::TotpService::AlreadyEnabled)
    end
  end

  describe "#enable!" do
    it "enables 2FA with valid password and TOTP code" do
      data = service.generate_setup_data
      totp = ROTP::TOTP.new(data[:secret])
      code = totp.now

      backup_codes = service.enable!(
        password: "hackthegrid",
        otp_secret: data[:secret],
        totp_code: code
      )

      expect(backup_codes).to be_an(Array)
      expect(backup_codes.length).to eq(8)
      expect(hackr.reload.otp_required_for_login?).to be true
      expect(hackr.otp_secret).to eq(data[:secret])
    end

    it "raises InvalidPassword with wrong password" do
      data = service.generate_setup_data
      totp = ROTP::TOTP.new(data[:secret])

      expect {
        service.enable!(password: "wrong", otp_secret: data[:secret], totp_code: totp.now)
      }.to raise_error(Grid::TotpService::InvalidPassword)
    end

    it "raises InvalidCode with wrong TOTP code" do
      data = service.generate_setup_data

      expect {
        service.enable!(password: "hackthegrid", otp_secret: data[:secret], totp_code: "000000")
      }.to raise_error(Grid::TotpService::InvalidCode)
    end

    it "raises AlreadyEnabled when called twice" do
      data = service.generate_setup_data
      totp = ROTP::TOTP.new(data[:secret])
      service.enable!(password: "hackthegrid", otp_secret: data[:secret], totp_code: totp.now)

      expect {
        service.enable!(password: "hackthegrid", otp_secret: data[:secret], totp_code: totp.now)
      }.to raise_error(Grid::TotpService::AlreadyEnabled)
    end
  end

  describe "#verify!" do
    let(:secret) { ROTP::Base32.random }

    before do
      hackr.update_columns(otp_required_for_login: true)
      hackr.otp_secret = secret
      hackr.save!(validate: false)
      hackr.generate_backup_codes!
    end

    it "returns :totp for valid TOTP code" do
      code = ROTP::TOTP.new(secret).now
      expect(service.verify!(code)).to eq(:totp)
    end

    it "returns :backup_code for valid backup code" do
      codes = hackr.generate_backup_codes!
      expect(service.verify!(codes.first)).to eq(:backup_code)
    end

    it "consumes backup code on use" do
      codes = hackr.generate_backup_codes!
      service.verify!(codes.first)

      expect(hackr.reload.otp_backup_code_digests.length).to eq(7)
    end

    it "raises InvalidCode for wrong code" do
      expect { service.verify!("000000") }
        .to raise_error(Grid::TotpService::InvalidCode)
    end

    it "raises NotEnabled when 2FA is off" do
      hackr.update_columns(otp_required_for_login: false)

      expect { service.verify!("123456") }
        .to raise_error(Grid::TotpService::NotEnabled)
    end
  end

  describe "#disable!" do
    let(:secret) { ROTP::Base32.random }

    before do
      hackr.update_columns(otp_required_for_login: true)
      hackr.otp_secret = secret
      hackr.save!(validate: false)
      hackr.generate_backup_codes!
    end

    it "disables 2FA with valid password and TOTP code" do
      code = ROTP::TOTP.new(secret).now
      service.disable!(password: "hackthegrid", totp_code: code)

      hackr.reload
      expect(hackr.otp_required_for_login?).to be false
      expect(hackr.otp_secret).to be_nil
      expect(hackr.otp_backup_code_digests).to be_nil
    end

    it "raises InvalidPassword with wrong password" do
      code = ROTP::TOTP.new(secret).now

      expect { service.disable!(password: "wrong", totp_code: code) }
        .to raise_error(Grid::TotpService::InvalidPassword)
    end

    it "raises InvalidCode with wrong TOTP code" do
      expect { service.disable!(password: "hackthegrid", totp_code: "000000") }
        .to raise_error(Grid::TotpService::InvalidCode)
    end
  end

  describe "#regenerate_backup_codes!" do
    let(:secret) { ROTP::Base32.random }

    before do
      hackr.update_columns(otp_required_for_login: true)
      hackr.otp_secret = secret
      hackr.save!(validate: false)
      hackr.generate_backup_codes!
    end

    it "generates new codes and flushes old ones" do
      old_digests = hackr.otp_backup_code_digests.dup
      code = ROTP::TOTP.new(secret).now

      new_codes = service.regenerate_backup_codes!(password: "hackthegrid", totp_code: code)

      expect(new_codes.length).to eq(8)
      expect(hackr.reload.otp_backup_code_digests).not_to eq(old_digests)
    end

    it "raises InvalidPassword with wrong password" do
      code = ROTP::TOTP.new(secret).now

      expect { service.regenerate_backup_codes!(password: "wrong", totp_code: code) }
        .to raise_error(Grid::TotpService::InvalidPassword)
    end

    it "raises NotEnabled when 2FA is off" do
      hackr.update_columns(otp_required_for_login: false)

      expect { service.regenerate_backup_codes!(password: "hackthegrid", totp_code: "123456") }
        .to raise_error(Grid::TotpService::NotEnabled)
    end
  end

  describe "#disable_admin!" do
    let(:admin) { create(:grid_hackr, :admin) }

    before do
      hackr.update_columns(otp_required_for_login: true)
      hackr.otp_secret = ROTP::Base32.random
      hackr.save!(validate: false)
    end

    it "disables 2FA without requiring target credentials" do
      service.disable_admin!(acting_admin: admin)

      hackr.reload
      expect(hackr.otp_required_for_login?).to be false
      expect(hackr.otp_secret).to be_nil
    end

    it "raises NotEnabled when 2FA is not active" do
      hackr.update_columns(otp_required_for_login: false)

      expect { service.disable_admin!(acting_admin: admin) }
        .to raise_error(Grid::TotpService::NotEnabled)
    end
  end

  describe "#status" do
    it "returns disabled status for new hackr" do
      result = service.status
      expect(result[:enabled]).to be false
      expect(result[:backup_codes_remaining]).to eq(0)
    end

    it "returns enabled status with backup code count" do
      hackr.update_columns(otp_required_for_login: true)
      hackr.generate_backup_codes!

      result = service.status
      expect(result[:enabled]).to be true
      expect(result[:backup_codes_remaining]).to eq(8)
    end
  end
end
