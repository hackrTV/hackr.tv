class CodeMailer < ApplicationMailer
  default from: "null@beacon.hackr.tv"

  def token_expired(error)
    @error = error

    track_email
    mail(
      to: "x@hackr.tv",
      subject: "hackr.tv Code Sync: GitHub token expired"
    )
  end
end
