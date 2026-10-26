# == Schema Information
#
# Table name: chat_message_reactions
# Database name: primary
#
#  id              :integer          not null, primary key
#  emote_slug      :string(32)       not null
#  created_at      :datetime         not null
#  chat_message_id :integer          not null
#  grid_hackr_id   :integer          not null
#
# Indexes
#
#  index_chat_message_reactions_on_grid_hackr_id  (grid_hackr_id)
#  index_chat_message_reactions_unique            (chat_message_id,grid_hackr_id,emote_slug) UNIQUE
#
# Foreign Keys
#
#  chat_message_id  (chat_message_id => chat_messages.id) ON DELETE => cascade
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :chat_message_reaction do
    association :chat_message
    association :grid_hackr
    emote_slug { "wave" }
  end
end
