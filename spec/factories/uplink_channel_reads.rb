# == Schema Information
#
# Table name: uplink_channel_reads
# Database name: primary
#
#  id                   :integer          not null, primary key
#  read_at              :datetime         not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  chat_channel_id      :integer          not null
#  grid_hackr_id        :integer          not null
#  last_read_message_id :integer          default(0), not null
#
# Indexes
#
#  index_uplink_channel_reads_on_chat_channel_id  (chat_channel_id)
#  index_uplink_channel_reads_on_grid_hackr_id    (grid_hackr_id)
#  index_uplink_channel_reads_unique              (grid_hackr_id,chat_channel_id) UNIQUE
#
# Foreign Keys
#
#  chat_channel_id  (chat_channel_id => chat_channels.id)
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#
FactoryBot.define do
  factory :uplink_channel_read do
    association :grid_hackr
    association :chat_channel
    last_read_message_id { 0 }
    read_at { Time.current }
  end
end
