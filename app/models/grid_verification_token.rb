# == Schema Information
#
# Table name: grid_verification_tokens
# Database name: primary
#
#  id            :integer          not null, primary key
#  expires_at    :datetime         not null
#  ip_address    :string
#  purpose       :string           not null
#  token         :string           not null
#  used_at       :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_grid_verification_tokens_on_grid_hackr_id              (grid_hackr_id)
#  index_grid_verification_tokens_on_grid_hackr_id_and_purpose  (grid_hackr_id,purpose)
#  index_grid_verification_tokens_on_token                      (token) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class GridVerificationToken < ApplicationRecord
  EXPIRATION_HOURS = 24

  belongs_to :grid_hackr

  before_create :generate_token
  before_create :set_expiration

  validates :purpose, presence: true, inclusion: {in: %w[password_reset]}
  validates :token, uniqueness: true, allow_nil: true

  scope :valid, -> { where(used_at: nil).where("expires_at > ?", Time.current) }
  scope :for_purpose, ->(purpose) { where(purpose: purpose) }

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

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at = EXPIRATION_HOURS.hours.from_now
  end
end
