class GridMailer < ApplicationMailer
  default from: "null@beacon.hackr.tv"

  def registration_verification(token)
    @token = token
    @verification_url = grid_verify_url(token: token.token)

    mail(
      to: token.email,
      subject: "Complete your registration on THE PULSE GRID"
    )
  end

  def password_reset(token)
    @token = token
    @reset_url = grid_password_reset_url(token: token.token)

    mail(
      to: token.grid_hackr.email,
      subject: "Password reset for THE PULSE GRID"
    )
  end
end
