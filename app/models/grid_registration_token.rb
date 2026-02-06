# == Schema Information
#
# Table name: grid_registration_tokens
# Database name: primary
#
#  id         :integer          not null, primary key
#  email      :string           not null
#  token      :string           not null
#  expires_at :datetime         not null
#  used_at    :datetime
#  ip_address :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_grid_registration_tokens_on_token  (token) UNIQUE
#  index_grid_registration_tokens_on_email  (email)
#
class GridRegistrationToken < ApplicationRecord
  EXPIRATION_HOURS = 24

  before_validation :normalize_email
  before_create :generate_token
  before_create :set_expiration

  validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :token, uniqueness: true, allow_nil: true

  scope :valid, -> { where(used_at: nil).where("expires_at > ?", Time.current) }
  scope :for_email, ->(email) { where(email: email.to_s.downcase.strip) }

  def expired?
    expires_at < Time.current
  end

  def used?
    used_at.present?
  end

  def valid_for_use?
    !expired? && !used?
  end

  def mark_used!
    update!(used_at: Time.current)
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at = EXPIRATION_HOURS.hours.from_now
  end
end
