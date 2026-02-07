class EmailObserver
  def self.delivered_email(mail)
    SentEmail.create!(
      to: Array(mail.to).join(", "),
      from: Array(mail.from).join(", "),
      subject: mail.subject,
      text_body: mail.text_part&.decoded,
      html_body: mail.html_part&.decoded,
      mailer_class: mail["X-Mailer-Class"]&.value,
      mailer_action: mail["X-Mailer-Action"]&.value,
      emailable_type: mail["X-Emailable-Type"]&.value,
      emailable_id: mail["X-Emailable-Id"]&.value
    )
  rescue => e
    Rails.logger.error("[EmailObserver] Failed to record sent email: #{e.message}")
  end
end
