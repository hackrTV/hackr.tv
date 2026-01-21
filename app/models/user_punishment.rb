class UserPunishment < ApplicationRecord
  PUNISHMENT_TYPES = %w[squelch blackout].freeze

  belongs_to :grid_hackr
  belongs_to :issued_by, class_name: "GridHackr"

  validates :punishment_type, presence: true, inclusion: {in: PUNISHMENT_TYPES, message: "%{value} is not a valid punishment type"}

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :squelches, -> { where(punishment_type: "squelch") }
  scope :blackouts, -> { where(punishment_type: "blackout") }

  # Get active punishment for a hackr of a specific type
  def self.active_for(hackr, type = nil)
    scope = active.where(grid_hackr: hackr)
    scope = scope.where(punishment_type: type) if type
    scope
  end

  # Check if a hackr is currently squelched
  def self.squelched?(hackr)
    active_for(hackr, "squelch").exists?
  end

  # Check if a hackr is currently blackouted (banned from chat)
  def self.blackouted?(hackr)
    active_for(hackr, "blackout").exists?
  end

  # Issue a squelch punishment (temporary mute)
  def self.squelch!(hackr, issued_by:, duration_minutes: nil, reason: nil)
    expires_at = duration_minutes&.minutes&.from_now

    punishment = create!(
      grid_hackr: hackr,
      issued_by: issued_by,
      punishment_type: "squelch",
      expires_at: expires_at,
      reason: reason
    )

    ModerationLog.log_action(
      actor: issued_by,
      target: hackr,
      action: "squelch",
      reason: reason,
      duration_minutes: duration_minutes
    )

    punishment
  end

  # Issue a blackout punishment (full chat ban)
  def self.blackout!(hackr, issued_by:, duration_minutes: nil, reason: nil)
    expires_at = duration_minutes&.minutes&.from_now

    punishment = create!(
      grid_hackr: hackr,
      issued_by: issued_by,
      punishment_type: "blackout",
      expires_at: expires_at,
      reason: reason
    )

    ModerationLog.log_action(
      actor: issued_by,
      target: hackr,
      action: "blackout",
      reason: reason,
      duration_minutes: duration_minutes
    )

    punishment
  end

  # Lift a punishment
  def lift!(lifted_by)
    action = (punishment_type == "squelch") ? "unsquelch" : "unblackout"

    ModerationLog.log_action(
      actor: lifted_by,
      target: grid_hackr,
      action: action
    )

    destroy
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def permanent?
    expires_at.nil?
  end

  def time_remaining
    return nil if permanent? || expired?
    expires_at - Time.current
  end
end
