class ModerationLog < ApplicationRecord
  ACTIONS = %w[squelch blackout unsquelch unblackout drop_packet restore_packet].freeze

  belongs_to :actor, class_name: "GridHackr"
  belongs_to :target, class_name: "GridHackr", optional: true
  belongs_to :chat_message, optional: true

  validates :action, presence: true, inclusion: {in: ACTIONS, message: "%{value} is not a valid action"}

  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_actor, ->(actor) { where(actor: actor) }
  scope :by_target, ->(target) { where(target: target) }

  # Create a log entry for a moderation action
  def self.log_action(actor:, action:, target: nil, chat_message: nil, reason: nil, duration_minutes: nil)
    create!(
      actor: actor,
      target: target,
      chat_message: chat_message,
      action: action,
      reason: reason,
      duration_minutes: duration_minutes
    )
  end
end
