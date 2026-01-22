class ChatChannel < ApplicationRecord
  has_many :chat_messages, dependent: :destroy

  validates :slug, presence: true, uniqueness: true, format: {with: /\A[a-z0-9_-]+\z/, message: "only allows lowercase letters, numbers, underscores, and hyphens"}
  validates :name, presence: true
  validates :slow_mode_seconds, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :minimum_role, inclusion: {in: GridHackr::ROLE_LEVELS.keys, message: "%{value} is not a valid role"}

  scope :active, -> { where(is_active: true) }
  scope :requiring_livestream, -> { where(requires_livestream: true) }

  # Check if channel is currently available (considering livestream requirement)
  def currently_available?
    return false unless is_active?
    return HackrStream.current_live.present? if requires_livestream?
    true
  end

  # Check if a hackr can access this channel based on role requirements (for transmitting)
  def accessible_by?(hackr)
    return false unless hackr
    return false unless currently_available?

    hackr_level = hackr.role_level
    required_level = GridHackr::ROLE_LEVELS[minimum_role] || 0

    hackr_level >= required_level
  end

  # Check if channel is viewable (read-only access)
  # Anonymous users can only view livestream channels (e.g., #live)
  def viewable_by?(hackr)
    return false unless currently_available?

    # Anonymous users can only view livestream channels
    return requires_livestream? unless hackr

    # Logged-in users must meet role requirements
    accessible_by?(hackr)
  end

  # Get the broadcast stream name for ActionCable
  def stream_name
    "uplink:#{slug}"
  end
end
