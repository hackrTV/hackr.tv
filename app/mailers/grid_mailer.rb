class GridMailer < ApplicationMailer
  default from: "null@beacon.hackr.tv"

  def registration_verification(token)
    @token = token
    @verification_url = grid_verify_url(token: token.token)

    track_email
    mail(
      to: token.email,
      subject: "Complete your registration on THE PULSE GRID"
    )
  end

  def password_reset(token)
    @token = token
    @reset_url = grid_password_reset_url(token: token.token)

    track_email(emailable: token.grid_hackr)
    mail(
      to: token.grid_hackr.email,
      subject: "Password reset for THE PULSE GRID"
    )
  end

  def email_change_verification(token)
    @token = token
    @verification_url = grid_confirm_email_change_url(token: token.token)

    track_email(emailable: token.grid_hackr)
    mail(
      to: token.new_email,
      subject: "Confirm your new email for THE PULSE GRID"
    )
  end

  def email_change_notification(hackr, old_email)
    @hackr = hackr
    @old_email = old_email

    track_email(emailable: hackr)
    mail(
      to: old_email,
      subject: "Your email was changed on THE PULSE GRID"
    )
  end
end
