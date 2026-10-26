# == Schema Information
#
# Table name: chat_messages
# Database name: primary
#
#  id              :integer          not null, primary key
#  content         :text             not null
#  dropped         :boolean          default(FALSE), not null
#  dropped_at      :datetime
#  pinned_at       :datetime
#  source          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  chat_channel_id :integer          not null
#  grid_hackr_id   :integer          not null
#  hackr_stream_id :integer
#  pinned_by_id    :integer
#  reply_to_id     :integer
#
# Indexes
#
#  index_chat_messages_on_chat_channel_id                 (chat_channel_id)
#  index_chat_messages_on_chat_channel_id_and_created_at  (chat_channel_id,created_at)
#  index_chat_messages_on_dropped                         (dropped)
#  index_chat_messages_on_grid_hackr_id                   (grid_hackr_id)
#  index_chat_messages_on_hackr_stream_id                 (hackr_stream_id)
#  index_chat_messages_on_reply_to_id                     (reply_to_id)
#  index_chat_messages_pinned                             (chat_channel_id,pinned_at) WHERE pinned_at IS NOT NULL
#
# Foreign Keys
#
#  chat_channel_id  (chat_channel_id => chat_channels.id)
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#  hackr_stream_id  (hackr_stream_id => hackr_streams.id)
#  pinned_by_id     (pinned_by_id => grid_hackrs.id) ON DELETE => nullify
#  reply_to_id      (reply_to_id => chat_messages.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :chat_message do
    association :chat_channel
    association :grid_hackr
    sequence(:content) { |n| "Test message #{n}" }
    dropped { false }
    dropped_at { nil }

    trait :dropped do
      dropped { true }
      dropped_at { Time.current }
    end

    trait :with_stream do
      association :hackr_stream
    end

    trait :pinned do
      pinned_at { 1.hour.ago }
      pinned_by { association :grid_hackr, :operator }
    end
  end
end
