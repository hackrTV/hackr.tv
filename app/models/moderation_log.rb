# == Schema Information
#
# Table name: moderation_logs
# Database name: primary
#
#  id               :integer          not null, primary key
#  action           :string           not null
#  duration_minutes :integer
#  reason           :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  actor_id         :integer          not null
#  chat_message_id  :integer
#  target_id        :integer
#
# Indexes
#
#  index_moderation_logs_on_action           (action)
#  index_moderation_logs_on_actor_id         (actor_id)
#  index_moderation_logs_on_chat_message_id  (chat_message_id)
#  index_moderation_logs_on_created_at       (created_at)
#  index_moderation_logs_on_target_id        (target_id)
#
# Foreign Keys
#
#  actor_id         (actor_id => grid_hackrs.id)
#  chat_message_id  (chat_message_id => chat_messages.id)
#  target_id        (target_id => grid_hackrs.id)
#
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
