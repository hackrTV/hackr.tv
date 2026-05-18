# frozen_string_literal: true

module DataAudit
  # Base class for all data audit checks. Subclasses must:
  #   1. Define SEVERITY ("critical", "warning", or "info")
  #   2. Define DOMAIN ("grid" or "music")
  #   3. Implement #violations returning an array of violation hashes
  #
  # Each violation hash must contain:
  #   { title:, subject_type:, subject_id: }
  #
  # Use build_violation to get the correct shape with fingerprint included.
  class Check
    def violations
      raise NotImplementedError, "#{self.class}#violations must be implemented"
    end

    def check_name
      self.class.name.demodulize.underscore
    end

    def severity
      self.class::SEVERITY
    end

    def domain
      self.class::DOMAIN
    end

    def self.fingerprint_for(subject_type, subject_id, detail_key: "")
      Digest::SHA256.hexdigest(
        [name, subject_type.to_s, subject_id.to_s, detail_key.to_s].join(":")
      )
    end

    private

    def build_violation(title:, subject_type:, subject_id:, detail_key: "")
      {
        fingerprint: self.class.fingerprint_for(subject_type, subject_id, detail_key: detail_key),
        check_name: check_name,
        title: title,
        severity: severity,
        domain: domain,
        subject_type: subject_type,
        subject_id: subject_id
      }
    end
  end
end
