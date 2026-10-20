# frozen_string_literal: true

# Anonymized roster handle for the Uplink members pane. The pane shows who
# is connected without listing aliases (anti-enumeration: identities stay
# in the packets people choose to send), so each hackr gets a stable,
# non-reversible callsign — an HMAC of the hackr id keyed from
# secret_key_base via the key generator (no new secret to manage;
# rotating secret_key_base reshuffles every callsign, which is fine).
# The same token is the DOM key the members controller matches against
# the viewer's own token to reveal "you". 6 hex digits = 24 bits: a
# cosmetic collision is unlikely at any realistic channel size and only
# affects the label, never identity.
module Uplink
  module Callsign
    PREFIX = "SIG"
    LENGTH = 6

    def self.token(hackr_id)
      OpenSSL::HMAC.hexdigest("SHA256", key, "uplink/callsign:#{hackr_id}")[0, LENGTH].upcase
    end

    def self.label(hackr_id)
      "#{PREFIX}-#{token(hackr_id)}"
    end

    def self.key
      @key ||= Rails.application.key_generator.generate_key("uplink/callsign/v1", 32)
    end
  end
end
