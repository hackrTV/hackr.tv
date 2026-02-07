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
class SentEmail < ApplicationRecord
  belongs_to :emailable, polymorphic: true, optional: true
end
