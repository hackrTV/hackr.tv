# frozen_string_literal: true

class TerminalMailer < ApplicationMailer
  default from: "null@beacon.hackr.tv"

  def suspicious_activity(flags, since:)
    @flags = flags
    @since = since
    @generated_at = Time.current

    track_email
    mail(
      to: "x@hackr.tv",
      subject: "[TERMINAL] #{flags.size} suspicious activity flag#{flags.size == 1 ? '' : 's'} detected"
    )
  end
end
