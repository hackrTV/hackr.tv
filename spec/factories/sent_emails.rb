# == Schema Information
#
# Table name: sent_emails
# Database name: primary
#
#  id             :integer          not null, primary key
#  emailable_type :string
#  from           :string           not null
#  html_body      :text
#  mailer_action  :string           not null
#  mailer_class   :string           not null
#  subject        :string           not null
#  text_body      :text
#  to             :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  emailable_id   :integer
#
# Indexes
#
#  index_sent_emails_on_created_at  (created_at)
#  index_sent_emails_on_emailable   (emailable_type,emailable_id)
#
FactoryBot.define do
  factory :sent_email do
    to { "hackr@example.com" }
    from { "null@beacon.hackr.tv" }
    subject { "Test email" }
    mailer_class { "GridMailer" }
    mailer_action { "registration_verification" }
  end
end
