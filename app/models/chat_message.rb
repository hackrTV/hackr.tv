# == Schema Information
#
# Table name: chat_messages
# Database name: primary
#
#  id              :integer          not null, primary key
#  content         :text             not null
#  dropped         :boolean          default(FALSE), not null
#  dropped_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  chat_channel_id :integer          not null
#  grid_hackr_id   :integer          not null
#  hackr_stream_id :integer
#
# Indexes
#
#  index_chat_messages_on_chat_channel_id                 (chat_channel_id)
#  index_chat_messages_on_chat_channel_id_and_created_at  (chat_channel_id,created_at)
#  index_chat_messages_on_dropped                         (dropped)
#  index_chat_messages_on_grid_hackr_id                   (grid_hackr_id)
#  index_chat_messages_on_hackr_stream_id                 (hackr_stream_id)
#
# Foreign Keys
#
#  chat_channel_id  (chat_channel_id => chat_channels.id)
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#  hackr_stream_id  (hackr_stream_id => hackr_streams.id)
#
class ChatMessage < ApplicationRecord
  include ProfanityFilterable

  belongs_to :chat_channel
  belongs_to :grid_hackr
  belongs_to :hackr_stream, optional: true

  validates :content, presence: true, length: {maximum: 512}
  filter_profanity :content

  scope :active, -> { where(dropped: false) }
  scope :dropped, -> { where(dropped: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_channel, ->(channel) { where(chat_channel: channel) }

  after_create_commit :broadcast_new_packet
  after_update_commit :broadcast_dropped_change, if: :saved_change_to_dropped?

  # Drop a message (moderation action)
  def drop!
    update(dropped: true, dropped_at: Time.current)
  end

  # Restore a dropped message
  def restore!
    update(dropped: false, dropped_at: nil)
  end

  private

  def broadcast_new_packet
    ActionCable.server.broadcast(chat_channel.stream_name, {
      type: "new_packet",
      packet: packet_json
    })
  end

  def broadcast_dropped_change
    if dropped?
      ActionCable.server.broadcast(chat_channel.stream_name, {
        type: "packet_dropped",
        packet_id: id
      })
    else
      ActionCable.server.broadcast(chat_channel.stream_name, {
        type: "packet_restored",
        packet_id: id,
        packet: packet_json
      })
    end
  end

  def packet_json
    {
      id: id,
      content: content,
      created_at: created_at.iso8601,
      dropped: dropped,
      grid_hackr: {
        id: grid_hackr_id,
        hackr_alias: grid_hackr&.hackr_alias,
        role: grid_hackr&.role
      },
      hackr_stream_id: hackr_stream_id
    }
  end
end
