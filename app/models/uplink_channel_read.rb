# One high-water mark per hackr per Uplink channel: the newest packet id
# they have seen there (Phase 2 item 5). The /uplink sidebar counts the
# active packets above it (Uplink::Unread). Moved by the shell render
# (the channel on screen), by the viewer's own sends, and by the shell's
# ack (Uplink::ReadsController) while they watch a channel at the bottom.
# Never moves backwards: a late ack from a tab that fell behind must not
# resurrect a count. Seeded at the channel's newest packet the first time
# a hackr sees a channel in the sidebar, so a new hackr (or a new
# channel) starts caught up instead of at 99+.
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
class UplinkChannelRead < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :chat_channel

  validates :grid_hackr_id, uniqueness: {scope: :chat_channel_id}
  validates :last_read_message_id, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  before_validation :set_read_at, on: :create

  # Raise the mark to message_id (no-op when it is already there or
  # higher). The unique index settles a concurrent first mark: the loser
  # retries once and takes the update path.
  def self.mark!(hackr, channel, message_id, attempt: 0)
    message_id = message_id.to_i
    row = find_or_initialize_by(grid_hackr: hackr, chat_channel: channel)
    return row if row.persisted? && row.last_read_message_id >= message_id

    row.last_read_message_id = message_id
    row.read_at = Time.current
    row.save!
    row
  rescue ActiveRecord::RecordNotUnique
    raise if attempt.positive?

    mark!(hackr, channel, message_id, attempt: 1)
  end

  # First sight of a channel: start caught up at its newest packet. One
  # insert for every channel id in the hash; rows that already exist are
  # left alone (ON CONFLICT DO NOTHING on the unique pair).
  def self.seed!(hackr, newest_by_channel_id)
    return 0 if newest_by_channel_id.empty?

    now = Time.current
    rows = newest_by_channel_id.map do |channel_id, newest|
      {grid_hackr_id: hackr.id, chat_channel_id: channel_id, last_read_message_id: newest.to_i,
       read_at: now, created_at: now, updated_at: now}
    end
    insert_all(rows, unique_by: :index_uplink_channel_reads_unique).length
  end

  private

  def set_read_at
    self.read_at ||= Time.current
  end
end
