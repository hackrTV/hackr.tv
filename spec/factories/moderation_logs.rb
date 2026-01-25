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
FactoryBot.define do
  factory :moderation_log do
    association :actor, factory: :grid_hackr
    association :target, factory: :grid_hackr
    action { "squelch" }
    reason { "Test moderation action" }
    duration_minutes { nil }

    trait :squelch do
      action { "squelch" }
    end

    trait :blackout do
      action { "blackout" }
    end

    trait :lift do
      action { "lift_punishment" }
    end

    trait :drop_packet do
      action { "drop_packet" }
      association :chat_message
    end

    trait :with_duration do
      duration_minutes { 30 }
    end
  end
end
