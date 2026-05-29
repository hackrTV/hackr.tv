# == Schema Information
#
# Table name: grid_messages
# Database name: primary
#
#  id              :integer          not null, primary key
#  content         :text
#  message_type    :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer
#  room_id         :integer
#  target_hackr_id :integer
#
# Indexes
#
#  index_grid_messages_on_grid_hackr_id    (grid_hackr_id)
#  index_grid_messages_on_room_id          (room_id)
#  index_grid_messages_on_target_hackr_id  (target_hackr_id)
#
FactoryBot.define do
  factory :grid_message do
    association :grid_hackr
    association :room, factory: :grid_room
    message_type { "say" }
    content { "Test message in THE PULSE GRID" }
    target_hackr { nil }

    trait :whisper do
      message_type { "whisper" }
      association :target_hackr, factory: :grid_hackr
    end

    trait :broadcast do
      message_type { "broadcast" }
      room { nil }
    end

    trait :system do
      message_type { "system" }
      grid_hackr { nil }
    end
  end
end
