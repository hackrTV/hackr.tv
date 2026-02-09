FactoryBot.define do
  factory :sent_email do
    to { "hackr@example.com" }
    from { "null@beacon.hackr.tv" }
    subject { "Test email" }
    mailer_class { "GridMailer" }
    mailer_action { "registration_verification" }
  end
end
