class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  private

  def track_email(emailable: nil)
    headers["X-Mailer-Class"] = self.class.name
    headers["X-Mailer-Action"] = action_name
    if emailable
      headers["X-Emailable-Type"] = emailable.class.name
      headers["X-Emailable-Id"] = emailable.id.to_s
    end
  end
end
