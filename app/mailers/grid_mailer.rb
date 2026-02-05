class GridMailer < ApplicationMailer
  default from: "noreply@hackr.tv"

  def registration_verification(token)
    @token = token
    @verification_url = grid_verify_url(token: token.token)

    mail(
      to: token.email,
      subject: "Complete your registration on THE PULSE GRID"
    )
  end
end
