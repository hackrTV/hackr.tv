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
  after_update_commit :broadcast_packet_dropped, if: :saved_change_to_dropped?

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

  def broadcast_packet_dropped
    return unless dropped?

    ActionCable.server.broadcast(chat_channel.stream_name, {
      type: "packet_dropped",
      packet_id: id
    })
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
