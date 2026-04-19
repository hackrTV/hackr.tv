# frozen_string_literal: true

module Grid
  class TotpService
    class Error < StandardError; end
    class InvalidPassword < Error; end
    class InvalidCode < Error; end
    class AlreadyEnabled < Error; end
    class NotEnabled < Error; end

    ISSUER = "hackr.tv"

    def initialize(hackr)
      @hackr = hackr
    end

    # Generate a fresh TOTP secret and return setup data.
    # Does NOT persist anything — secret is only saved on enable.
    def generate_setup_data
      raise AlreadyEnabled, "2FA is already enabled." if @hackr.otp_required_for_login?

      secret = ROTP::Base32.random
      totp = ROTP::TOTP.new(secret, issuer: ISSUER)
      uri = totp.provisioning_uri(@hackr.hackr_alias)

      qr = RQRCode::QRCode.new(uri)
      svg = qr.as_svg(module_size: 4, standalone: true, use_path: true)

      {secret: secret, provisioning_uri: uri, qr_svg: svg}
    end

    # Verify a TOTP code against a staged (not yet persisted) secret,
    # then enable 2FA and generate backup codes.
    def enable!(password:, otp_secret:, totp_code:)
      raise AlreadyEnabled, "2FA is already enabled." if @hackr.otp_required_for_login?
      raise InvalidPassword, "Password incorrect." unless @hackr.authenticate(password)

      totp = ROTP::TOTP.new(otp_secret, issuer: ISSUER)
      unless totp.verify(totp_code.to_s.strip, drift_behind: 30, drift_ahead: 30)
        raise InvalidCode, "Invalid TOTP code. Try again."
      end

      backup_codes = nil

      ActiveRecord::Base.transaction do
        @hackr.otp_secret = otp_secret
        @hackr.otp_required_for_login = true
        @hackr.save!(validate: false)
        backup_codes = @hackr.generate_backup_codes!
      end

      backup_codes
    end

    # Verify a TOTP code or backup code for a pending login.
    # Returns :totp or :backup_code indicating which succeeded.
    def verify!(code)
      code = code.to_s.strip
      raise NotEnabled, "2FA is not enabled." unless @hackr.otp_required_for_login?

      return :totp if @hackr.verify_otp(code)
      return :backup_code if @hackr.consume_backup_code!(code)

      raise InvalidCode, "Invalid code. Access denied."
    end

    # Regenerate backup codes. Requires password and valid TOTP code.
    # Flushes old codes entirely.
    def regenerate_backup_codes!(password:, totp_code:)
      raise NotEnabled, "2FA is not enabled." unless @hackr.otp_required_for_login?
      raise InvalidPassword, "Password incorrect." unless @hackr.authenticate(password)
      raise InvalidCode, "Invalid TOTP code." unless @hackr.verify_otp(totp_code.to_s.strip)

      @hackr.generate_backup_codes!
    end

    # Disable 2FA. Requires password and valid TOTP code.
    def disable!(password:, totp_code:)
      raise NotEnabled, "2FA is not enabled." unless @hackr.otp_required_for_login?
      raise InvalidPassword, "Password incorrect." unless @hackr.authenticate(password)
      raise InvalidCode, "Invalid TOTP code." unless @hackr.verify_otp(totp_code.to_s.strip)

      @hackr.clear_totp!
    end

    # Admin recovery — no credentials required from target hackr.
    def disable_admin!(acting_admin:)
      raise NotEnabled, "2FA is not enabled for #{@hackr.hackr_alias}." unless @hackr.otp_required_for_login?

      @hackr.clear_totp!
      Rails.logger.info("[2FA] Admin TOTP reset: target=#{@hackr.hackr_alias} admin=#{acting_admin.hackr_alias} ip=n/a")
    end

    def status
      {
        enabled: @hackr.otp_required_for_login?,
        backup_codes_remaining: @hackr.otp_backup_code_digests.to_a.length
      }
    end
  end
end
